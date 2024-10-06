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
  cidr_block = "10.90.0.0/16"
}

resource "aws_subnet" "public-1" {
  vpc_id     = aws_vpc.test-app-vpc.id
  cidr_block = "10.90.10.0/24"
  availability_zone = "us-east-1a"

  tags = {
    Name = "public-1"
  }
}

resource "aws_subnet" "public-2" {
  vpc_id     = aws_vpc.test-app-vpc.id
  cidr_block = "10.90.20.0/24"
  availability_zone = "us-east-1b"

  tags = {
    Name = "public-2"
  }
}

resource "aws_subnet" "private-1" {
  vpc_id     = aws_vpc.test-app-vpc.id
  cidr_block = "10.90.11.0/24"
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

resource "aws_route_table" "public-1" {
  vpc_id = aws_vpc.test-app-vpc.id

  route {
    cidr_block = "0.0.0.0/0"
    gateway_id = aws_internet_gateway.gw.id
  }

  

  tags = {
    Name = "public-1-route-table"
  }
}

resource "aws_route_table" "public-2" {
  vpc_id = aws_vpc.test-app-vpc.id

  route {
    cidr_block = "0.0.0.0/0"
    gateway_id = aws_internet_gateway.gw.id
  }
  
  tags = {
    Name = "public-2-route-table"
  }
}

# Public Subnet 1 ve Route Table 1 ilişkilendirilmesi
resource "aws_route_table_association" "public-1-association" {
  subnet_id      = aws_subnet.public-1.id
  route_table_id = aws_route_table.public-1.id
}

# Public Subnet 2 ve Route Table 2 ilişkilendirilmesi
resource "aws_route_table_association" "public-2-association" {
  subnet_id      = aws_subnet.public-2.id
  route_table_id = aws_route_table.public-2.id
}

# Elastic IP oluşturma
resource "aws_eip" "nat_eip" {
  vpc = true
}

# NAT Gateway oluşturma (Public Subnet'te olmalı)
resource "aws_nat_gateway" "nat_gw" {
  allocation_id = aws_eip.nat_eip.id
  subnet_id     = aws_subnet.public-1.id  # NAT Gateway'i public subnet'te oluşturuyoruz

  tags = {
    Name = "nat-gateway"
  }
}

# Private Route Table oluşturma
resource "aws_route_table" "private-1" {
  vpc_id = aws_vpc.test-app-vpc.id

  route {
    cidr_block = "0.0.0.0/0" # Internet trafiği için
    nat_gateway_id = aws_nat_gateway.nat_gw.id
  }

  tags = {
    Name = "private-1-route-table"
  }
}

# Private Subnet ve Route Table ilişkilendirilmesi
resource "aws_route_table_association" "private-1-association" {
  subnet_id      = aws_subnet.private-1.id
  route_table_id = aws_route_table.private-1.id
}

resource "aws_security_group" "ec2-sec-grp" {
  name = "ec2-sec-grp"
  tags = {
    Name = "ec2-sec-grp"
  }

  ingress {
    from_port = 0
    protocol  = "-1"
    to_port   = 0
    self = true
  }
  
  ingress {
    from_port   = 80
    protocol    = "tcp"
    to_port     = 80
    cidr_blocks = ["0.0.0.0/0"]
  }

  ingress {
    from_port   = 443
    protocol    = "tcp"
    to_port     = 443
    cidr_blocks = ["0.0.0.0/0"]
  }

  ingress {
    from_port   = 3000
    protocol    = "tcp"
    to_port     = 3000
    cidr_blocks = ["0.0.0.0/0"]
  }

  ingress {
    from_port   = 5000
    protocol    = "tcp"
    to_port     = 5000
    cidr_blocks = ["0.0.0.0/0"]
  }

  ingress {
      from_port = 22
      protocol = "tcp"
      to_port = 22
      cidr_blocks = [ "0.0.0.0/0" ]
  }

  ingress {
      from_port = 8080
      protocol = "tcp"
      to_port = 8080
      cidr_blocks = [ "0.0.0.0/0" ]
  }

  ingress {
    from_port   = 6443
    to_port     = 6443
    protocol    = "tcp"
    cidr_blocks = ["10.90.10.0/24", "10.90.20.0/24", "10.90.11.0/24"]
  }  

  egress {
      from_port = 0
      protocol = -1
      to_port = 0
      cidr_blocks = [ "0.0.0.0/0" ]
  }
}



# 8. EC2 Instance Oluşturma
resource "aws_instance" "master" {
  ami           = "ami-0ebfd941bbafe70c6"
  instance_type = "t3a.medium"
  subnet_id     = aws_subnet.public-1.id
  security_groups = [aws_security_group.ec2-sec-grp.name]
  iam_instance_profile = aws_iam_instance_profile.ec2_instance_profile.name


  root_block_device {
    volume_size = 30
  }

  # Dinamik inventory dosyasını oluştur
  provisioner "local-exec" {
    command = <<EOT
      echo "[master]" > ./inventory
      echo "${self.public_ip}" >> ./inventory
    EOT
  }

  provisioner "local-exec" {
    command = "ansible-playbook -i ./inventory AI-Aplication/Ansible/playbooks/master_setup.yml"
  }

  tags = {
    Name = "master"
  }
}

resource "aws_instance" "worker-1" {
  ami           = "ami-0ebfd941bbafe70c6"
  instance_type = "t3a.medium"
  subnet_id     = aws_subnet.public-1.id
  security_groups = [aws_security_group.ec2-sec-grp.name]
  iam_instance_profile = aws_iam_instance_profile.ec2_instance_profile.name


  root_block_device {
    volume_size = 30
  }

  # Worker node'ları inventory dosyasına ekle
  provisioner "local-exec" {
    command = <<EOT
      echo "[workers]" >> ./inventory
      echo "${self.public_ip}" >> ./inventory
    EOT
  }

  provisioner "local-exec" {
    command = "ansible-playbook -i ./inventory AI-Aplication/Ansible/playbooks/worker_setup.yml"
  }

  tags = {
    Name = "worker-1"
  }
}

resource "aws_instance" "worker-2" {
  ami           = ami-0ebfd941bbafe70c6
  instance_type = "t3a.medium"
  subnet_id     = aws_subnet.public-2.id
  security_groups = [aws_security_group.ec2-sec-grp.name]
  iam_instance_profile = aws_iam_instance_profile.ec2_instance_profile.name


  # 30 GB EBS Volume
  root_block_device {
    volume_size = 30
    
  }
 # Worker node'ları inventory dosyasına ekle
  provisioner "local-exec" {
    command = <<EOT
      echo "${self.public_ip}" >> ./inventory
    EOT
  }

  provisioner "local-exec" {
    command = "ansible-playbook -i ./inventory AI-Aplication/Ansible/playbooks/worker_setup.yml"
  }
  # # User Data - Shell Script ile Kurulum
  # user_data = file("setup.sh")

  tags = {
    Name = "worker-2"
  }
}

resource "aws_db_subnet_group" "rds_subnet_group" {
  name       = "rds-subnet-group"
  subnet_ids = [aws_subnet.private-1.id]  # Özel subnet'i kullanıyoruz

  tags = {
    Name = "RDS subnet group"
  }
}

resource "aws_db_instance" "default" {
  allocated_storage    = 10
  db_name              = "deid"                 # MYSQL_DATABASE
  engine               = "mysql"
  engine_version       = "8.0"
  instance_class       = "db.t3.micro"
  username             = "raife"                # MYSQL_USER
  password             = "123"                  # MYSQL_PASSWORD
  parameter_group_name = "default.mysql8.0"
  skip_final_snapshot  = true
  publicly_accessible  = false                  # Özel subnet, internet erişimi yok
  port                 = 3306

  # RDS Subnet Grubu
  subnet_group_name = aws_db_subnet_group.rds_subnet_group.name

  # Güvenlik Grubu (Varsayılan bir güvenlik grubu eklenebilir veya özelleştirilebilir)
  vpc_security_group_ids = [aws_security_group.rds_security_group.id]  # Güvenlik grubu ID'si
}

resource "aws_security_group" "rds_security_group" {
  name        = "rds-sg"
  description = "Allow MySQL traffic"
  vpc_id      = aws_vpc.test-app-vpc.id

  # Ingress rule for MySQL (port 3306) allowing internal VPC access
  ingress {
    from_port   = 3306
    to_port     = 3306
    protocol    = "tcp"
    cidr_blocks = ["10.90.0.0/16"]  # VPC içi erişim
  }

  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"  # Allow all outbound traffic
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

