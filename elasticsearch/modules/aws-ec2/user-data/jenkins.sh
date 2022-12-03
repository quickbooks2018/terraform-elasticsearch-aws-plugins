#!/bin/bash
# Os: Ubuntu20 LTS


apt update -y
apt install -y awscli

# Docker Installation
curl -fsSL https://get.docker.com -o get-docker.sh
sh get-docker.sh
rm -f get-docker.sh




systemctl start docker
systemctl enable docker


# Jenkins Setup
# Docker Named Volumes
$(aws ecr get-login --no-include-email --region us-east-1)
docker volume create jenkins
docker run --name jenkins -d -v jenkins:/var/jenkins_home -p 80:8080 -v $(which docker):/usr/bin/docker -v /var/run/docker.sock:/var/run/docker.sock --restart unless-stopped 023560845085.dkr.ecr.us-east-1.amazonaws.com/jenkins:latest

