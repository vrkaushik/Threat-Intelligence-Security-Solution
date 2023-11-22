##Password change

#Stop the deployment stack if it’s running:
docker-compose down

#Run this command to generate the hash of your new password. Once the container launches, input the new password and press Enter.

docker run --rm -ti wazuh/wazuh-indexer:4.6.0 bash /usr/share/wazuh-indexer/plugins/opensearch-security/tools/hash.sh

#Copy the generated hash.

#Open the config/wazuh_indexer/internal_users.yml file. Locate the block for the user you are changing password for.

#Replace the hash.

#admin user
...
admin:
  hash: "2y$12$U8Ye45u7OMb9MAYrtYndyuVtGRD4CvCDdm1PTKeyyvLSFvS23jan6"
  reserved: true
  backend_roles:
  - "admin"
  description: "Demo admin user"
...

#kibanaserver user
...
kibanaserver:
  hash: "2y$12$U8Ye45u7OMb9MAYrtYndyuVtGRD4CvCDdm1PTKeyyvLSFvS23jan6"
  reserved: true
  description: "Demo kibanaserver user"
...

#Open the docker-compose.yml file. Change all occurrences of the old password with the new one. For example, for a single-node deployment:

#admin user
...
services:
  wazuh.manager:
    ...
    environment:
      - INDEXER_URL=https://wazuh.indexer:9200
      - INDEXER_USERNAME=admin
      - INDEXER_PASSWORD=Stuxnet@123
      - FILEBEAT_SSL_VERIFICATION_MODE=full
      - SSL_CERTIFICATE_AUTHORITIES=/etc/ssl/root-ca.pem
      - SSL_CERTIFICATE=/etc/ssl/filebeat.pem
      - SSL_KEY=/etc/ssl/filebeat.key
      - API_USERNAME=wazuh-wui
      - API_PASSWORD=MyS3cr37P450r.*-
  ...
  wazuh.dashboard:
    ...
    environment:
      - INDEXER_USERNAME=admin
      - INDEXER_PASSWORD=Stuxnet@123
      - WAZUH_API_URL=https://wazuh.manager
      - DASHBOARD_USERNAME=kibanaserver
      - DASHBOARD_PASSWORD=kibanaserver
      - API_USERNAME=wazuh-wui
      - API_PASSWORD=MyS3cr37P450r.*-
  ...
