#!/bin/bash

# Update system packages and install prerequisites
echo "Updating system packages and installing prerequisites..."
sudo apt-get update -y
sudo apt-get upgrade -y
sudo apt-get install -y docker.io docker-compose git curl

# Add current user to docker group to avoid sudo for docker commands
echo "Adding current user to docker group..."
sudo usermod -aG docker ubuntu  # AWS Ubuntu default user is 'ubuntu'

# Start and enable Docker service
echo "Starting Docker service..."
sudo systemctl start docker
sudo systemctl enable docker

# Clone DevLake repository
echo "Cloning DevLake repository..."
git clone https://github.com/apache/incubator-devlake.git
cd incubator-devlake

# Set up environment variables
echo "Setting up environment variables..."
cat <<EOT >> .env
# MySQL configuration
MYSQL_ROOT_PASSWORD=admin
MYSQL_USER=merico
MYSQL_PASSWORD=merico
MYSQL_DATABASE=lake
MYSQL_PORT=3306

# DevLake configuration
DEVLAKE_PORT=8080
DEVLAKE_ENV_MODE=development
EOT

# Build and start DevLake containers
echo "Building and starting DevLake containers..."
docker-compose up -d

# Wait for services to initialize
echo "Waiting for services to initialize (60 seconds)..."
sleep 60

# Check container status
echo "Checking container status..."
docker-compose ps

# Display installation completion message
echo "DevLake installation completed!"
echo "Access the web interface at: http://$(curl -s http://169.254.169.254/latest/meta-data/public-ipv4):8080"
