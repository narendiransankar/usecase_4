#!/bin/bash
# Fix: Add swap to prevent freezes (critical for t3.medium)
sudo fallocate -l 2G /swapfile
sudo chmod 600 /swapfile
sudo mkswap /swapfile
sudo swapon /swapfile
echo '/swapfile none swap sw 0 0' | sudo tee -a /etc/fstab

# Update system and install prerequisites
sudo apt-get update -y
sudo apt-get upgrade -y
sudo apt-get install -y docker.io docker-compose git curl jq

# Add user to docker group
sudo usermod -aG docker ubuntu

# Start and enable Docker
sudo systemctl start docker
sudo systemctl enable docker

# Clone DevLake
git clone https://github.com/apache/incubator-devlake.git
cd incubator-devlake

# Configure environment
cat <<EOT >> .env
MYSQL_ROOT_PASSWORD=admin
MYSQL_USER=merico
MYSQL_PASSWORD=merico
MYSQL_DATABASE=lake
DEVLAKE_PORT=8080
EOT

# Start containers
docker-compose up -d --build

# ---- Fix: Advanced Readiness Check ----
# Wait for DevLake API to respond (up to 3 mins)
timeout=180
elapsed=0
while [ $elapsed -lt $timeout ]; do
  if curl -s http://localhost:8080; then
    echo "DevLake is up!" >> /var/log/user-data.log
    break
  fi
  echo "Waiting for DevLake (${elapsed}s elapsed)..." >> /var/log/user-data.log
  sleep 10
  elapsed=$((elapsed+10))
done

# Final status
docker-compose ps >> /var/log/user-data.log
echo "Access DevLake at: http://$(curl -s http://169.254.169.254/latest/meta-data/public-ipv4):8080" >> /var/log/user-data.log
