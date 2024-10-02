#! /bin/bash
sudo dnf update -y
sudo dnf upgrade -y
hostnamectl set-hostname kube-master
sudo dnf install docker -y
sudo systemctl docker start
sudo systemctl docker enable
sudo usermod -aG docker ec2-user
newgrp docker
sudo dnf install git -y
sudo curl -SL https://github.com/docker/compose/releases/download/v2.29.6/docker-compose-linux-x86_64 -o /usr/local/bin/docker-compose
sudo chmod +x /usr/local/bin/docker-compose
