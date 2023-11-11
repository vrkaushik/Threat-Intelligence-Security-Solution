sudo apt-get update
sudo apt-get install -y \
    apt-transport-https \
    ca-certificates \
    software-properties-common \
    openssl \
    curl 


sudo wget https://packages.wazuh.com/4.x/apt/pool/main/w/wazuh-agent/wazuh-agent_4.6.0-1_amd64.deb && sudo WAZUH_MANAGER='${wazuh_external_ip}' WAZUH_AGENT_NAME='bastion' dpkg -i ./wazuh-agent_4.6.0-1_amd64.deb



sudo systemctl daemon-reload
sudo systemctl enable wazuh-agent
sudo systemctl start wazuh-agent

# copy SSH config
sudo mv /home/admin/sshd_config /etc/ssh/sshd_config
sudo systemctl restart sshd
