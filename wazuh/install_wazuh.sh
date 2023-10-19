#!/bin/bash

# Deployment on Docker

# This section details the process of installing Wazuh on Docker.

# Docker is an open platform for building, delivering, and running applications inside software containers. Docker containers package up software, including everything needed to run: code, runtime, system tools, system libraries, and settings. Docker enables separating applications from infrastructure. This guarantees that the application always runs the same, regardless of the environment the container is running on. Containers run in the cloud or on-premises.

# You can install Wazuh using the Docker images we have created, such as wazuh/wazuh-manager, wazuh/wazuh-indexer, and wazuh/wazuh-dashboard. You can find all the Wazuh Docker images in the Docker hub.

# Docker Installation

## Requirements

# 1. Container Memory: We recommend configuring the Docker host with at least 6 GB of memory. Depending on the deployment and usage, Wazuh indexer memory consumption varies. Therefore, allocate the recommended memory for a complete stack deployment to work properly.

# 2. Increase max_map_count on your host (Linux): Wazuh indexer creates many memory-mapped areas. So you need to set the kernel to give a process at least 262,144 memory-mapped areas.

#    Increase max_map_count on your Docker host:
sysctl -w vm.max_map_count=262144


#    Update the vm.max_map_count setting in /etc/sysctl.conf to set this value permanently. 
#    To verify after rebooting, run sysctl vm.max_map_count.

# Docker Engine: For Linux/Unix machines, Docker requires an amd64 architecture system running kernel version 3.10 or later. Open a terminal and use uname -r to display and check your kernel version:
uname -r

# Install Docker
# On Ubuntu/Debian machines:

curl -sSL https://get.docker.com/ | sh


# Start the Docker service:

# Systemd:

systemctl start docker

# Note: If you would like to use Docker as a non-root user, you should add your user to the docker group with something like the following command:

usermod -aG docker your-user

# Log out and log back in for this to take effect.

# Docker Compose
# The Wazuh Docker deployment requires Docker Compose 1.29 or later. Follow these steps to install it:

# Download the Docker Compose binary:

curl -L "https://github.com/docker/compose/releases/download/v2.12.2/docker-compose-$(uname -s)-$(uname -m)" -o /usr/local/bin/docker-compose


# Grant execution permissions:

chmod +x /usr/local/bin/docker-compose


# Test the installation to ensure everything is fine:

docker-compose --version

# Output:
Docker Compose version v2.12.2

# Wazuh Docker deployment
# Single-node deployment: Deploys one Wazuh manager, indexer, and dashboard node.

# Clone the Wazuh repository to your system:

git clone https://github.com/wazuh/wazuh-docker.git -b v4.5.3

# Then enter into the single-node directory to execute all the commands described below within this directory.

# Provide a group of certificates for each node in the stack to secure communication between the nodes. You have two alternatives to provide these certificates:

# Generate self-signed certificates for each cluster node.

# We have created a Docker image to automate certificate generation using the Wazuh certs gen tool.

# If your system uses a proxy, add the following to the generate-indexer-certs.yml file. If not, skip this particular step:

 environment:
  - HTTP_PROXY=YOUR_PROXY_ADDRESS_OR_DNS

# A completed example looks like:

# # Wazuh App Copyright (C) 2021 Wazuh Inc. (License GPLv2)
 version: '3'

 services:
   generator:
     image: wazuh/wazuh-certs-generator:0.0.1
     hostname: wazuh-certs-generator
     volumes:
       - ./config/wazuh_indexer_ssl_certs/:/certificates/
       - ./config/certs.yml:/config/certs.yml
     environment:
       - HTTP_PROXY=YOUR_PROXY_ADDRESS_OR_DNS

# Execute the following command to get the desired certificates:

 docker-compose -f generate-indexer-certs.yml run --rm generator

# This saves the certificates into the config/wazuh_indexer_ssl_certs directory.

#3. Start the Wazuh single-node deployment using docker-compose:

#Foreground:

docker-compose up

#Background:

docker-compose up -d

#The default username and password for the Wazuh dashboard are admin and SecretPassword. For additional security, you can change the default password for the Wazuh indexer admin user.

#Exposed ports
#By default, the stack exposes the following ports:
1514 - Wazuh TCP
1515 - Wazuh TCP 
514 - Wazuh UDP 
55000 - Wazuh API 
9200 - Wazuh indexer HTTPS 
443 - Wazuh dashboard HTTPS
