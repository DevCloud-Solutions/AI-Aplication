terraform {
  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = "~> 5.0"
    }
  }
}

# Configure the AWS Provider
provider "aws" {
  region = "us-east-1"
}

resource "aws_vpc" "test-app-vpc" {
  cidr_block           = "10.90.0.0/16"
  enable_dns_support   = true
  enable_dns_hostnames = true
  tags = {
    Name = "test-app-vpc"
  }
}

resource "aws_subnet" "public-1" {
  vpc_id            = aws_vpc.test-app-vpc.id
  cidr_block        = "10.90.10.0/24"
  availability_zone = "us-east-1a"
  tags = {
    Name = "public-1"
  }
}

resource "aws_subnet" "public-2" {
  vpc_id            = aws_vpc.test-app-vpc.id
  cidr_block        = "10.90.20.0/24"
  availability_zone = "us-east-1b"
  tags = {
    Name = "public-2"
  }
}

resource "aws_subnet" "private-1" {
  vpc_id            = aws_vpc.test-app-vpc.id
  cidr_block        = "10.90.11.0/24"
  availability_zone = "us-east-1a"
  tags = {
    Name = "private-1"
  }
}

resource "aws_internet_gateway" "gw" {
  vpc_id = aws_vpc.test-app-vpc.id
  tags = {
    Name = "igw"
  }
}

resource "aws_route_table" "public" {
  vpc_id = aws_vpc.test-app-vpc.id
  route {
    cidr_block = "0.0.0.0/0"
    gateway_id = aws_internet_gateway.gw.id
  }
  tags = {
    Name = "public-route-table"
  }
}

resource "aws_route_table_association" "public-1-association" {
  subnet_id      = aws_subnet.public-1.id
  route_table_id = aws_route_table.public.id
}

resource "aws_route_table_association" "public-2-association" {
  subnet_id      = aws_subnet.public-2.id
  route_table_id = aws_route_table.public.id
}

resource "aws_eip" "nat_eip" {
  domain = "vpc"
}

resource "aws_nat_gateway" "nat_gw" {
  allocation_id = aws_eip.nat_eip.id
  subnet_id     = aws_subnet.public-1.id
  tags = {
    Name = "nat-gateway"
  }
}

resource "aws_route_table" "private" {
  vpc_id = aws_vpc.test-app-vpc.id
  route {
    cidr_block = "0.0.0.0/0"
    nat_gateway_id = aws_nat_gateway.nat_gw.id
  }
  tags = {
    Name = "private-route-table"
  }
}

resource "aws_route_table_association" "private-1-association" {
  subnet_id      = aws_subnet.private-1.id
  route_table_id = aws_route_table.private.id
}

resource "aws_security_group" "ec2-sec-grp" {
  name        = "ec2-sec-grp"
  description = "Security group for EC2 instances"
  vpc_id      = aws_vpc.test-app-vpc.id

  ingress {
    from_port   = 22
    to_port     = 22
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"] # SSH erişimini sınırlandırabilirsiniz
  }

  ingress {
    from_port   = 80
    to_port     = 80
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }

  ingress {
    from_port   = 443
    to_port     = 443
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }

  ingress {
    from_port   = 6443
    to_port     = 6443
    protocol    = "tcp"
    cidr_blocks = ["10.90.10.0/24", "10.90.20.0/24", "10.90.11.0/24"] # Yalnızca VPC içi erişim
  }

  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }

  tags = {
    Name = "ec2-sec-grp"
  }
}

resource "aws_instance" "master" {
  ami                    = "ami-0ebfd941bbafe70c6"
  instance_type          = "t3a.medium"
  key_name               = "test"
  subnet_id              = aws_subnet.public-1.id
  security_groups        = [aws_security_group.ec2-sec-grp.id]
  iam_instance_profile   = aws_iam_instance_profile.ec2_instance_profile.name

  root_block_device {
    volume_size = 30
  }

  tags = {
    Name = "K8s-Master"
  }
}

resource "aws_instance" "workerone" {
  ami                    = "ami-0ebfd941bbafe70c6"
  instance_type          = "t3a.medium"
  key_name               = "test"
  subnet_id              = aws_subnet.public-1.id
  security_groups        = [aws_security_group.ec2-sec-grp.id]
  iam_instance_profile   = aws_iam_instance_profile.ec2_instance_profile.name

  root_block_device {
    volume_size = 30
  }

  tags = {
    Name = "K8s-Worker-1"
  }
}

resource "aws_instance" "workertwo" {
  ami                    = "ami-0ebfd941bbafe70c6"
  instance_type          = "t3a.medium"
  key_name               = "test"
  subnet_id              = aws_subnet.public-2.id
  security_groups        = [aws_security_group.ec2-sec-grp.id]
  iam_instance_profile   = aws_iam_instance_profile.ec2_instance_profile.name

  root_block_device {
    volume_size = 30
  }

  tags = {
    Name = "K8s-Worker-2"
  }
}

resource "aws_db_subnet_group" "rds_subnet_group" {
  name       = "rds-subnet-group"
  subnet_ids = [aws_subnet.private-1.id]
  tags = {
    Name = "RDS subnet group"
  }
}

resource "aws_db_instance" "default" {
  allocated_storage    = 10
  db_name              = "deid"
  engine               = "mysql"
  engine_version       = "8.0"
  instance_class       = "db.t3.micro"
  username             = "raife"
  password             = "123"
  parameter_group_name = "default.mysql8.0"
  skip_final_snapshot  = true
  publicly_accessible  = false
  port                 = 3306

  db_subnet_group_name = aws_db_subnet_group.rds_subnet_group.name

  vpc_security_group_ids = [aws_security_group.rds_security_group.id]
}


resource "aws_security_group" "rds_security_group" {
  name        = "rds-sg"
  description = "Allow MySQL traffic"
  vpc_id      = aws_vpc.test-app-vpc.id

  ingress {
    from_port   = 3306
    to_port     = 3306
    protocol    = "tcp"
    cidr_blocks = ["10.90.0.0/16"]
  }

  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }

  tags = {
    Name = "rds-security-group"
  }
}

# AWS ECR Repository Oluşturma
resource "aws_ecr_repository" "backend_repo" {
  name = "backend-repo"
}

resource "aws_ecr_repository" "frontend_repo" {
  name = "frontend-repo"
}

resource "aws_iam_role" "ec2_role" {
  name = "ec2-ecr-role"

  assume_role_policy = <<EOF
  {
    "Version": "2012-10-17",
    "Statement": [
      {
        "Effect": "Allow",
        "Principal": {
          "Service": "ec2.amazonaws.com"
        },
        "Action": "sts:AssumeRole"
      }
    ]
  }
  EOF
}

resource "aws_iam_policy" "ecr_policy" {
  name = "ECRAccessPolicy"
  policy = <<EOF
  {
    "Version": "2012-10-17",
    "Statement": [
      {
        "Effect": "Allow",
        "Action": [
          "ecr:GetDownloadUrlForLayer",
          "ecr:BatchGetImage",
          "ecr:BatchCheckLayerAvailability"
        ],
        "Resource": "*"
      },
      {
        "Effect": "Allow",
        "Action": "ecr:GetAuthorizationToken",
        "Resource": "*"
      }
    ]
  }
  EOF
}

resource "aws_iam_role_policy_attachment" "ec2_role_policy_attachment" {
  role       = aws_iam_role.ec2_role.name
  policy_arn = aws_iam_policy.ecr_policy.arn
}

resource "aws_iam_instance_profile" "ec2_instance_profile" {
  name = "ec2_instance_profile"
  role = aws_iam_role.ec2_role.name
}

output "master_public_ip" {
  value = aws_instance.master.public_ip
  description = "Public IP address of the master instance"
}

output "workerone_public_ip" {
  value = aws_instance.workerone.public_ip
  description = "Public IP address of the first worker instance"
}

output "workertwo_public_ip" {
  value = aws_instance.workertwo.public_ip
  description = "Public IP address of the second worker instance"
}
