#!/bin/bash
sudo apt update -y
sudo apt install -y docker.io
sudo systemctl start docker
sudo systemctl enable docker
sleep 10
sudo docker run -d -p 80:80 \
  -e OPENPROJECT_SECRET_KEY_BASE=secret \
  -e OPENPROJECT_HOST__NAME=0.0.0.0:80 \
  -e OPENPROJECT_HTTPS=false \
  openproject/community:12
