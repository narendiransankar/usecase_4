#!/bin/bash
sudo apt update -y
sudo apt install -y docker.io git curl

# Enable and start Docker
sudo systemctl enable docker
sudo systemctl start docker

sudo usermod -aG docker ubuntu

sleep 10

# Install Docker Compose
sudo curl -L "https://github.com/docker/compose/releases/download/1.29.2/docker-compose-$(uname -s)-$(uname -m)" -o /usr/local/bin/docker-compose
sudo chmod +x /usr/local/bin/docker-compose

cd /home/ubuntu
git clone https://github.com/merico-dev/lake.git devlake-setup
cd devlake-setup
cp -arp devops/releases/lake-v0.21.0/docker-compose.yml ./
cp env.example .env
 echo "ENCRYPTION_SECRET=password123" >> .env
 docker-compose up -d
# Wait for services to initialize
sleep 30
        
