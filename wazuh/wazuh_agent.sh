#!/bin/bash

# Deploying Wazuh agents on Linux endpoints

# The agent runs on the host you want to monitor and communicates with the Wazuh server, sending data in near real-time through an encrypted and authenticated channel.

# The deployment of a Wazuh agent on a Linux system uses deployment variables that facilitate the task of installing, registering, and configuring the agent. Alternatively, if you want to download the Wazuh agent package directly, see the packages list section.

# Note: You need root user privileges to run all the commands described below.

# Add the Wazuh repository

# Add the Wazuh repository to download the official packages.

# Install the GPG key:

curl -s https://packages.wazuh.com/key/GPG-KEY-WAZUH | gpg --no-default-keyring --keyring gnupg-ring:/usr/share/keyrings/wazuh.gpg --import && chmod 644 /usr/share/keyrings/wazuh.gpg

# Add the repository:

echo "deb [signed-by=/usr/share/keyrings/wazuh.gpg] https://packages.wazuh.com/4.x/apt/ stable main" | tee -a /etc/apt/sources.list.d/wazuh.list

# Update the package information:

apt-get update

# Deploy a Wazuh agent

# To deploy the Wazuh agent on your endpoint, select your package manager and edit the WAZUH_MANAGER variable to contain your Wazuh manager IP address or hostname.

WAZUH_MANAGER="10.0.0.2" apt-get install wazuh-agent

# Enable and start the Wazuh agent service.

systemctl daemon-reload
systemctl enable wazuh-agent
systemctl start wazuh-agent

# The deployment process is now complete, and the Wazuh agent is successfully running on your Linux system.
