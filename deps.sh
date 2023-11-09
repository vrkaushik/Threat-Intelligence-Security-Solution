#!/bin/bash

# Update package repositories and install necessary dependencies
sudo apt-get update
sudo apt-get install -y \
    apt-transport-https \
    ca-certificates \
    nginx \ 
    openssl \ 
    curl \
    software-properties-common

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
if ! command -v docker >/dev/null 2>&1; then
    echo "Docker is not installed. Please install Docker first."
    exit 1
fi

if ! command -v docker-compose >/dev/null 2>&1; then
    echo "Docker Compose is not installed. Please install Docker Compose first."
    exit 1
fi

cd ~
mkdir docker
echo ${docker_compose_file} >> ~/docker/docker-compose.yml

ENV_VARIABLES = "MINIO_ROOT_USER=4bdae7e4-72ed-4c17-8c6f-377f0cb586f6
MINIO_ROOT_PASSWORD=117a1a6a-7e78-43f6-bfb4-c9181fc032db
RABBITMQ_DEFAULT_USER=guest
RABBITMQ_DEFAULT_PASS=guest
ELASTIC_MEMORY_SIZE=8G
CONNECTOR_HISTORY_ID=6ced2298-e830-4345-bc49-497569eb7297
CONNECTOR_EXPORT_FILE_STIX_ID=a5bf9db7-fa63-4886-860c-25416948fbdf
CONNECTOR_EXPORT_FILE_CSV_ID=f626f964-ecf8-4f19-99de-ca8a130c7d04
CONNECTOR_IMPORT_FILE_STIX_ID=c9fa9cae-5a3a-4c01-a711-c92fdba2ee6f
CONNECTOR_IMPORT_REPORT_ID=c730a6d4-559e-44fb-a469-953d387d3e38"

#Startig the docker containers for opencti
sudo docker compose up -d

#Configuring nginx reverse proxy
systemctl stop nginx
CERT_PATH="/etc/ssl/certs/localhost.crt"
KEY_PATH="/etc/ssl/private/localhost.key"

openssl req -x509 -nodes -days 365 -newkey rsa:2048 -keyout "$KEY_PATH" -out "$CERT_PATH" -subj "/CN=localhost"
chmod 600 "$KEY_PATH"
chmod 644 "$CERT_PATH"
echo ${nginx_conf_file} >> /etc/nginx/conf.d/default.conf

systemctl restart nginx