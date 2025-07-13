#!/bin/bash -ex

# ------------------------------
# 1. Expand Disk Space (Critical Fix)
# ------------------------------
# Check root filesystem usage
ROOT_USAGE=$(df -h / | awk 'NR==2 {print $5}' | cut -d'%' -f1)
if [ "$ROOT_USAGE" -gt 80 ]; then
  echo "Expanding root volume..."
  # For AWS EBS-backed instances:
  sudo growpart /dev/xvda 1
  sudo resize2fs /dev/xvda1
fi

# ------------------------------
# 2. System Preparation
# ------------------------------
# Add swap space (persistent across reboots)
sudo fallocate -l 4G /swapfile
sudo chmod 600 /swapfile
sudo mkswap /swapfile
sudo swapon /swapfile
echo '/swapfile none swap sw 0 0' | sudo tee -a /etc/fstab

# Clean up unnecessary files
sudo apt-get autoremove -y
sudo apt-get clean
sudo rm -rf /var/lib/apt/lists/* /tmp/* /var/tmp/*

# ------------------------------
# 3. Docker Installation & Configuration
# ------------------------------
# Remove conflicting Docker installations
sudo apt-get remove -y docker docker-engine docker.io containerd runc || true

# Install Docker dependencies
sudo apt-get update -y
sudo apt-get install -y \
    apt-transport-https \
    ca-certificates \
    curl \
    gnupg-agent \
    software-properties-common

# Add Docker GPG key and repository
curl -fsSL https://download.docker.com/linux/ubuntu/gpg  | sudo gpg --dearmor -o /usr/share/keyrings/docker-archive-keyring.gpg
echo "deb [arch=$(dpkg --print-architecture) signed-by=/usr/share/keyrings/docker-archive-keyring.gpg] https://download.docker.com/linux/ubuntu  $(lsb_release -cs) stable" | sudo tee /etc/apt/sources.list.d/docker.list > /dev/null

# Install Docker and Compose
sudo apt-get update -y
sudo apt-get install -y docker-ce docker-ce-cli containerd.io docker-compose

# Configure Docker
sudo mkdir -p /etc/docker
echo '{
  "experimental": true,
  "features": {
    "buildkit": true
  },
  "storage-driver": "overlay2",
  "max-concurrent-downloads": 10
}' | sudo tee /etc/docker/daemon.json

# Start Docker service
sudo systemctl enable docker
sudo systemctl restart docker

# Add user to docker group
sudo usermod -aG docker ubuntu
sudo su - ubuntu -c "docker info"  # Validate installation

# ------------------------------
# 4. Build & Run DevLake
# ------------------------------
# Clone repository
sudo su - ubuntu <<EOF
cd ~
git clone https://github.com/apache/incubator-devlake.git 
cd incubator-devlake

# Create optimized Docker configuration
cat << 'DOCKERFILE' > backend/Dockerfile.optimized
FROM --platform=linux/amd64 debian:bookworm-slim AS base
RUN apt-get update && apt-get install -y --no-install-recommends \\
    libssh2-1-dev \\
    libssl-dev \\
    zlib1g-dev \\
    gcc \\
    binutils \\
    cmake \\
    golang \\
    git \\
    make \\
    && rm -rf /var/lib/apt/lists/*

# ... [keep rest of your Dockerfile content] ...
DOCKERFILE

# Use optimized build command
DOCKER_BUILDKIT=1 docker-compose build \\
    --platform linux/amd64 \\
    --parallel \\
    --compress \\
    --force-rm \\
    --no-cache

docker-compose up -d

# Health check
timeout=300
while [ \$timeout -gt 0 ]; do
  if curl -s http://localhost:8080/api/health; then
    echo "DevLake is ready!" && break
  fi
  sleep 10
  timeout=\$((timeout-10))
done
EOF

# ------------------------------
# 5. Final Validation
# ------------------------------
# Get public IP
PUBLIC_IP=$(curl -s http://169.254.169.254/latest/meta-data/public-ipv4)

# Output access information
echo "DevLake available at: http://${PUBLIC_IP}:8080"
echo "Grafana available at: http://${PUBLIC_IP}:3000 (admin/admin)"
