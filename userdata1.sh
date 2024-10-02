#!/bin/bash
set -e

# 1. Sistemi güncelle
sudo yum update -y

# 2. Java ve gerekli paketlerin kurulumu (Jenkins için)
sudo amazon-linux-extras enable java-openjdk11
sudo yum install -y java-11-openjdk

# 3. Jenkins Kurulumu
sudo wget -O /etc/yum.repos.d/jenkins.repo https://pkg.jenkins.io/redhat-stable/jenkins.repo
sudo rpm --import https://pkg.jenkins.io/redhat-stable/jenkins.io.key
sudo yum install -y jenkins
sudo systemctl enable jenkins
sudo systemctl start jenkins

# 4. Ansible Kurulumu
sudo amazon-linux-extras install ansible2 -y

# 5. Docker Kurulumu (Kubernetes için gerekli)
sudo yum install -y docker
sudo systemctl start docker
sudo systemctl enable docker

# 6. Kubernetes (kubeadm, kubelet, kubectl) Kurulumu
cat <<EOF | sudo tee /etc/yum.repos.d/kubernetes.repo
[kubernetes]
name=Kubernetes
baseurl=https://packages.cloud.google.com/yum/repos/kubernetes-el7-\$basearch
enabled=1
gpgcheck=1
repo_gpgcheck=1
gpgkey=https://packages.cloud.google.com/yum/doc/yum-key.gpg
       https://packages.cloud.google.com/yum/doc/rpm-package-key.gpg
EOF

sudo yum install -y kubelet kubeadm kubectl
sudo systemctl enable kubelet
sudo systemctl start kubelet

# 7. Kubernetes Master Node Başlatma
sudo kubeadm init --pod-network-cidr=192.168.0.0/16

# 8. kubectl Konfigürasyonu (kubectl komutlarını çalıştırabilmek için)
mkdir -p $HOME/.kube
sudo cp -i /etc/kubernetes/admin.conf $HOME/.kube/config
sudo chown $(id -u):$(id -g) $HOME/.kube/config

# 9. Weave Net Pod Network Kurulumu (Kubernetes ağını başlatmak için)
kubectl apply -f https://git.io/weave-kube-1.6

# 10. Jenkins Web UI'ye Erişim Bilgisi
echo "Jenkins kurulumu tamamlandı. Web arayüzü: http://$(curl -s http://169.254.169.254/latest/meta-data/public-ipv4):8080"
echo "Jenkins initial admin password:"
sudo cat /var/lib/jenkins/secrets/initialAdminPassword

# 11. Son mesaj
echo "Jenkins, Ansible ve Kubernetes Master kurulumu tamamlandı!"