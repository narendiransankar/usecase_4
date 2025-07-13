#!/bin/bash
# Fix: Add swap to prevent freezes
sudo fallocate -l 2G /swapfile
sudo chmod 600 /swapfile
sudo mkswap /swapfile
sudo swapon /swapfile
echo '/swapfile none swap sw 0 0' | sudo tee -a /etc/fstab

# Update system and install prerequisites
sudo apt-get update -y
sudo apt-get upgrade -y
sudo apt-get install -y docker.io docker-compose git curl jq net-tools

# Enable BuildKit and set platform
echo '{"experimental": true}' | sudo tee /etc/docker/daemon.json
sudo systemctl restart docker

# Add user to docker group
sudo usermod -aG docker ubuntu
newgrp docker <<EONG
# Start and enable Docker
sudo systemctl start docker
sudo systemctl enable docker

# Clone DevLake with full path
git clone https://github.com/apache/incubator-devlake.git  /home/ubuntu/incubator-devlake
cd /home/ubuntu/incubator-devlake || exit 1

# Configure environment
cat <<EOT > .env
MYSQL_ROOT_PASSWORD=admin
MYSQL_USER=merico
MYSQL_PASSWORD=merico
MYSQL_DATABASE=lake
DEVLAKE_PORT=8080
EOT

# Create docker-compose.yml with platform specification
cat << 'EOF' > docker-compose.yml
version: '3.8'
services:
  mysql:
    image: mysql:8
    command: --performance-schema=off
    volumes:
      - mysql-storage:/var/lib/mysql
    environment:
      MYSQL_ROOT_PASSWORD: admin
      MYSQL_DATABASE: lake
      MYSQL_USER: merico
      MYSQL_PASSWORD: merico
    networks:
      - devlake-network
    mem_limit: 512m

  grafana:
    image: grafana/grafana:8.1.2
    volumes:
      - grafana-storage:/var/lib/grafana
    environment:
      GF_SECURITY_ADMIN_USER: admin
      GF_SECURITY_ADMIN_PASSWORD: admin
    ports:
      - "3000:3000"
    networks:
      - devlake-network
    mem_limit: 256m

  devlake:
    build:
      context: .
      dockerfile: backend/Dockerfile
      args:
        BUILDKIT_INLINE_CACHE: 1
        TARGETPLATFORM: linux/amd64  # Explicit platform specification
    volumes:
      - devlake-log:/app/logs
    ports:
      - "8080:8080"
    environment:
      MYSQL_ENDPOINT: mysql:3306
      MYSQL_DATABASE: lake
      MYSQL_USER: merico
      MYSQL_PASSWORD: merico
      MYSQL_ROOT_PASSWORD: admin
    depends_on:
      - mysql
    networks:
      - devlake-network
    mem_limit: 1g
    mem_reservation: 512m

volumes:
  mysql-storage:
  grafana-storage:
  devlake-log:

networks:
  devlake-network:
    driver: bridge
EOF

# Build with BuildKit enabled and platform specified
DOCKER_BUILDKIT=1 docker-compose build --no-cache --platform linux/amd64
docker-compose up -d

# Wait for services with proper check
timeout=180
elapsed=0
while [ $elapsed -lt $timeout ]; do
  if curl -s http://localhost:8080/api/health >/dev/null; then
    echo "DevLake is up!" >> /var/log/user-data.log
    break
  fi
  echo "Waiting for DevLake (${elapsed}s elapsed)..." >> /var/log/user-data.log
  sleep 10
  elapsed=$((elapsed+10))
done

# Get public IP safely
PUBLIC_IP=$(curl -s http://169.254.169.254/latest/meta-data/public-ipv4 || echo "IP_FETCH_FAILED")

# Final status
docker-compose ps >> /var/log/user-data.log
echo "Access DevLake at: http://${PUBLIC_IP}:8080" >> /var/log/user-data.log
EONG
