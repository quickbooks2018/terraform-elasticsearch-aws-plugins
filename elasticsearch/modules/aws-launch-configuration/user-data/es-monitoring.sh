#!/bin/bash
# ES Monitoring on AWS
# OS Ubuntu
# Maintainer Muhammad Asim <info@cloudgeeks.ca>
# https://www.elastic.co/guide/en/kibana/current/docker.html
# https://www.elastic.co/guide/en/kibana/current/settings.html


zonename='cloudgeeks.tk'
localip=$(curl -fs http://169.254.169.254/latest/meta-data/local-ipv4)
localip_host=$(echo "$((${-+"(${localip//./"+256*("}))))"}>>24&255))")

######################################
# Docker & Docker Compose Installation
######################################
curl -fsSL https://get.docker.com -o get-docker.sh
sh get-docker.sh
rm -f get-docker.sh

#########
# AWS CLI
#########
apt install -y unzip jq net-tools
curl "https://awscli.amazonaws.com/awscli-exe-linux-x86_64.zip" -o "awscliv2.zip"
unzip awscliv2.zip
./aws/install
rm -rf aws
rm -f *.zip
aws --version


ELASTIC_VERSION="7.17.7"
KIBANA="docker.elastic.co/kibana/kibana"

export ELASTIC_VERSION
export KIBANA

cat <<EOF > $PWD/kibana.yml
server.host: "0.0.0.0"
elasticsearch.hosts: [ "https://elasticsearch-cluster.cloudgeeks.tk" ]
EOF

cat <<EOF > Dockerfile
FROM ${KIBANA}:${ELASTIC_VERSION}
COPY kibana.yml /usr/share/kibana/config/kibana.yml
EOF

#########
# Route53
#########
KIBANA_URL='kibana.cloudgeeks.tk'
hostedzoneid=$(aws route53 list-hosted-zones-by-name --output json |  jq --arg name "${zonename}." -r '.HostedZones | .[] | select(.Name=="\($name)") | .Id' | awk -F '/' '{print $3}')
file=/tmp/record.json

cat << EOF > $file
{
  "Comment": "Update the A record set",
  "Changes": [
    {
      "Action": "UPSERT",
      "ResourceRecordSet": {
        "Name": "${KIBANA_URL}",
        "Type": "A",
        "TTL": 10,
        "ResourceRecords": [
          {
            "Value": "$localip"
          }
        ]
      }
    }
  ]
}
EOF

aws route53 change-resource-record-sets --hosted-zone-id $hostedzoneid --change-batch file://$file


cat << EOF > docker-compose.yaml
services:

  grafana:
    image: grafana/grafana:latest
    container_name: grafana-server
    restart: unless-stopped
    environment:
      - GF_SECURITY_ADMIN_USER=admin
      - GF_SECURITY_ADMIN_PASSWORD=cloudgeeks
    ports:
      - '80:3000'
    volumes:
      - grafana_data:/var/lib/grafana

  kibana:
    build:
      context: .
      dockerfile: Dockerfile
    image: custom_kibana:kibana
    container_name: kibana
    restart: unless-stopped
    ports:
      - '5601:5601'

volumes:
  grafana_data: {}
EOF

docker compose -p grafana up -d --build

# END