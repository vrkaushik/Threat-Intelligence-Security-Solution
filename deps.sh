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
    software-properties-common \
    nginx 

# Add Docker's official GPG key:
sudo apt-get update
sudo apt-get install -y ca-certificates curl gnupg
sudo install -m 0755 -d /etc/apt/keyrings
curl -fsSL https://download.docker.com/linux/debian/gpg | sudo gpg --dearmor -o /etc/apt/keyrings/docker.gpg
sudo chmod a+r /etc/apt/keyrings/docker.gpg

# Add the repository to Apt sources:
echo \
  "deb [arch="$(dpkg --print-architecture)" signed-by=/etc/apt/keyrings/docker.gpg] https://download.docker.com/linux/debian \
  "$(. /etc/os-release && echo "$VERSION_CODENAME")" stable" | \
  sudo tee /etc/apt/sources.list.d/docker.list > /dev/null
sudo apt-get update

sudo apt-get install -y docker-ce docker-ce-cli containerd.io docker-buildx-plugin docker-compose-plugin

# Check if Docker and Docker Compose are installed
if ! command  docker -v >/dev/null 2>&1; then
    echo "Docker is not installed on opencti. Please install Docker first."
    exit 1
fi

if ! command docker compose -v >/dev/null 2>&1; then
    echo "Docker Compose is not installed on opencti. Please install Docker Compose first."
    exit 1
fi


# sudo su -
cd 
git clone https://github.com/OpenCTI-Platform/docker.git

mv docker-compose.yml docker/docker-compose.yml

cd docker
(cat << EOF
OPENCTI_ADMIN_EMAIL=admin@opencti.io
OPENCTI_ADMIN_PASSWORD=Stuxnet@123#
OPENCTI_ADMIN_TOKEN=$(cat /proc/sys/kernel/random/uuid)
MINIO_ROOT_USER=$(cat /proc/sys/kernel/random/uuid)
MINIO_ROOT_PASSWORD=$(cat /proc/sys/kernel/random/uuid)
RABBITMQ_DEFAULT_USER=guest
RABBITMQ_DEFAULT_PASS=guest
ELASTIC_MEMORY_SIZE=8G
CONNECTOR_HISTORY_ID=$(cat /proc/sys/kernel/random/uuid)
CONNECTOR_EXPORT_FILE_STIX_ID=$(cat /proc/sys/kernel/random/uuid)
CONNECTOR_EXPORT_FILE_CSV_ID=$(cat /proc/sys/kernel/random/uuid)
CONNECTOR_IMPORT_FILE_STIX_ID=$(cat /proc/sys/kernel/random/uuid)
CONNECTOR_IMPORT_REPORT_ID=$(cat /proc/sys/kernel/random/uuid)
EOF
) > .env
export $(cat .env | grep -v "#" | xargs)
sudo sysctl -w vm.max_map_count=1048575
echo "vm.max_map_count=1048575" | sudo tee -a /etc/sysctl.conf
sudo sysctl -p

#Startig the docker containers for opencti
sudo docker compose up -d

#Configuring nginx reverse proxy
sudo systemctl stop nginx
CERT_PATH="/etc/ssl/certs/localhost.crt"
KEY_PATH="/etc/ssl/private/localhost.key"

sudo openssl req -x509 -nodes -days 365 -newkey rsa:2048 -keyout "$KEY_PATH" -out "$CERT_PATH" -subj "/CN=localhost"
sudo chmod 600 "$KEY_PATH"
sudo chmod 644 "$CERT_PATH"

sudo cp /home/admin/default.conf /etc/nginx/conf.d/default.conf

sudo systemctl restart nginx



# Configuring Wazuh Agent

# Install the GPG key:

# sudo curl -s https://packages.wazuh.com/key/GPG-KEY-WAZUH | sudo gpg --no-default-keyring --keyring gnupg-ring:/usr/share/keyrings/wazuh.gpg --import && sudo chmod 644 /usr/share/keyrings/wazuh.gpg

# # Add the repository:

# sudo echo "deb [signed-by=/usr/share/keyrings/wazuh.gpg] https://packages.wazuh.com/4.x/apt/ stable main" | sudo tee -a /etc/apt/sources.list.d/wazuh.list

# # Update the package information:

# sudo apt-get update

# #WAZUH_MANAGER = "${wazuh_external_ip}" 
# # sudo export WAZUH_MANAGER="${wazuh_external_ip}"
# # sudo echo 'export WAZUH_MANAGER="${wazuh_external_ip}"' >> ~/.bashrc

# sudo WAZUH_MANAGER="${wazuh_external_ip}" apt-get install wazuh-agent

# # Enable and start the Wazuh agent service.


sudo wget https://packages.wazuh.com/4.x/apt/pool/main/w/wazuh-agent/wazuh-agent_4.6.0-1_amd64.deb && sudo WAZUH_MANAGER='${wazuh_internal_ip}' WAZUH_AGENT_NAME='opencti' dpkg -i ./wazuh-agent_4.6.0-1_amd64.deb



sudo systemctl daemon-reload
sudo systemctl enable wazuh-agent
sudo systemctl start wazuh-agent

# The deployment process is now complete, and the Wazuh agent is successfully running on your Linux system.

