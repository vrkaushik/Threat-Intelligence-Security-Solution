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
