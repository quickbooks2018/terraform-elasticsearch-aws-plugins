#!/bin/bash
# ES cluster on AWS
# OS Ubuntu
# Maintainer Muhammad Asim <info@cloudgeeks.ca>

####################
# Elastic DATA Nodes
####################
CONTAINER_NAME='data'
ELASTIC_VERSION='7.17.7'
localip=$(curl -fs http://169.254.169.254/latest/meta-data/local-ipv4)
localip_host=$(echo "$((${-+"(${localip//./"+256*("}))))"}>>24&255))")
ec2_zone_id=$(curl -s http://169.254.169.254/latest/meta-data/placement/availability-zone)

export CONTAINER_NAME
export ELASTIC_VERSION

hostnamectl set-hostname ${CONTAINER_NAME}-${ec2_zone_id}

#########
# NETWORK
#########
# We will use host network


############
# MetricBeat
############
# https://raw.githubusercontent.com/elastic/beats/8.5/deploy/docker/metricbeat.docker.yml
echo '
---
metricbeat.config:
  modules:
    path: ${path.config}/modules.d/*.yml
    # Reload module configs as they change:
    reload.enabled: false
metricbeat.autodiscover:
  providers:
    - type: docker
      hints.enabled: true
metricbeat.modules:
- module: docker
  metricsets:
    - "container"
    - "cpu"
    - "diskio"
    - "healthcheck"
    - "info"
    #- "image"
    - "memory"
    - "network"
  hosts: ["unix:///var/run/docker.sock"]
  period: 10s
  enabled: true' > $PWD/metricbeat.yml

cat << EOF >> $PWD/metricbeat.yml
processors:
  - add_cloud_metadata: ~
output.elasticsearch:
  hosts: 'http://${localip}:9200'
EOF

############
# APM Server
############
KIBANA_URL='kibana.cloudgeeks.tk'
# https://raw.githubusercontent.com/elastic/apm-server/master/apm-server.docker.yml
cat << EOF > apm-server.yml
---
apm-server:
  host: 0.0.0.0:8200
  ssl.enabled: false
output.elasticsearch:
  hosts: ["http://${localip}:9200"]
kibana:
  enabled: true
  host: ["http://${KIBANA_URL}:5601"]
monitoring:
  enabled: true
EOF

############
# MetricBeat
############
cat << EOF > MetricBeatDockerfile
FROM docker.elastic.co/beats/metricbeat:${ELASTIC_VERSION}
COPY metricbeat.yml /usr/share/metricbeat/metricbeat.yml
EOF


############
# APM Server
############
cat << EOF > APMServerDockerfile
FROM docker.elastic.co/apm/apm-server:${ELASTIC_VERSION}
COPY apm-server.yml /usr/share/apm-server/apm-server.yml
EOF


###########
# DATA Node
###########
cat << EOF > elasticsearch.yml
cluster.name: "es-cluster"
cluster.initial_master_nodes: master-us-east-1a,master-us-east-1b,master-us-east-1c
bootstrap.memory_lock: true
node.master: false
node.data: true
node.ingest: false
#logger.level: ERROR
logger.level: DEBUG
logger.discovery: DEBUG
network.host: 0.0.0.0
cloud.node.auto_attributes: true
discovery.seed_providers: ec2
network.publish_host: _ec2_
transport.publish_host: _ec2_
transport.port: 9300
http.port: 9200
discovery.ec2.endpoint: ec2.us-east-1.amazonaws.com
discovery.ec2.availability_zones: us-east-1a,us-east-1b,us-east-1c
cluster.routing.allocation.awareness.attributes: aws_availability_zone
discovery.ec2.tag.role: elasticsearch
EOF

cat << EOF > DataNodeDockerfile
FROM es:es
COPY elasticsearch.yml /usr/share/elasticsearch/config/
USER root
RUN chown elasticsearch:elasticsearch /usr/share/elasticsearch/config/elasticsearch.yml
USER elasticsearch
WORKDIR /usr/share/elasticsearch
EOF


cat << EOF > docker-compose.yaml
services:

  elasticsearch:
    build:
      context: .
      dockerfile: DataNodeDockerfile
    image: es:es
    shm_size: '2gb'   # shared mem
    network_mode: host
    logging:
       driver: "awslogs"
       options:
         awslogs-group: "elasticsearch"
         awslogs-region: "us-east-1"
         awslogs-stream: ${CONTAINER_NAME}-${localip_host}
    container_name: ${CONTAINER_NAME}-${localip_host}
    hostname: ${CONTAINER_NAME}-${localip_host}
    restart: unless-stopped
    volumes:
      - /data:/usr/share/elasticsearch/data

    
    ulimits:
      memlock:
        soft: -1
        hard: -1

  metricbeat:
    build:
     context: .
     dockerfile: MetricBeatDockerfile
    image: metricbeat:metricbeat
    network_mode: host
    container_name: metricbeat
    restart: unless-stopped
    depends_on: ['elasticsearch']
    hostname: metricbeat
    command: ["--strict.perms=false", "-system.hostfs=/hostfs"]
    volumes:
      - /proc:/hostfs/proc:ro
      - /sys/fs/cgroup:/hostfs/sys/fs/cgroup:ro
      - /:/hostfs:ro
      - /var/run/docker.sock:/var/run/docker.sock:ro


  apm_server:
    build:
     context: .
     dockerfile: APMServerDockerfile
    image: apm:apm
    network_mode: host
    depends_on: ['elasticsearch']
    container_name: apm
    command: -e --strict.perms=false
    restart: unless-stopped
EOF

docker compose -p elasticsearch up -d --build
# End
