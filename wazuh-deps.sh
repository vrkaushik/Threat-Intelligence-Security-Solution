#!/bin/bash

# Update package repositories and install necessary dependencies
sudo apt-get update
sudo apt-get install -y \
    apt-transport-https \
    ca-certificates \
    software-properties-common \
    openssl \
    curl \
    jq \
    software-properties-common

# # Add Docker's official GPG key:
# sudo apt-get update
# sudo apt-get install -y ca-certificates curl gnupg
# sudo install -m 0755 -d /etc/apt/keyrings
# curl -fsSL https://download.docker.com/linux/debian/gpg | sudo gpg --dearmor -o /etc/apt/keyrings/docker.gpg
# sudo chmod a+r /etc/apt/keyrings/docker.gpg

# # Add the repository to Apt sources:
# echo \
#   "deb [arch="$(dpkg --print-architecture)" signed-by=/etc/apt/keyrings/docker.gpg] https://download.docker.com/linux/debian \
#   "$(. /etc/os-release && echo "$VERSION_CODENAME")" stable" | \
#   sudo tee /etc/apt/sources.list.d/docker.list > /dev/null
# sudo apt-get update

# sudo apt-get install -y docker-ce docker-ce-cli containerd.io docker-buildx-plugin docker-compose-plugin

#Installing docker
sudo curl -sSL https://get.docker.com/ | sh
sudo systemctl start docker
sudo curl -L "https://github.com/docker/compose/releases/download/v2.12.2/docker-compose-$(uname -s)-$(uname -m)" -o /usr/local/bin/docker-compose
sudo chmod +x /usr/local/bin/docker-compose
sudo docker-compose --version



#Check if Docker and Docker Compose are installed
if ! command docker -v >/dev/null 2>&1; then
    echo "Docker is not installed on wazuh. Please install Docker first."
    exit 1
fi

if ! command docker-compose -v >/dev/null 2>&1; then
    echo "Docker Compose is not installed on wazuh. Please install Docker Compose first."
    exit 1
fi


sudo sysctl -w vm.max_map_count=262144
echo "vm.max_map_count=262144" | sudo tee -a /etc/sysctl.conf
sudo sysctl -p

#Clone the Wazuh Repository to your system
git clone https://github.com/wazuh/wazuh-docker.git -b v4.6.0

cp docker-compose.yml wazuh-docker/single-node/docker-compose.ym

cd wazuh-docker/single-node

sudo docker-compose -f generate-indexer-certs.yml run --rm generator

sudo docker-compose up -d

