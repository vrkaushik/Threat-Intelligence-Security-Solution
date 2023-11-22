##Password change

#Stop the deployment stack if it’s running:
docker-compose down

#Run this command to generate the hash of your new password. Once the container launches, input the new password and press Enter.

docker run --rm -ti wazuh/wazuh-indexer:4.6.0 bash /usr/share/wazuh-indexer/plugins/opensearch-security/tools/hash.sh

#Copy the generated hash.

O#pen the config/wazuh_indexer/internal_users.yml file. Locate the block for the user you are changing password for.

#Replace the hash.

#admin user
...
admin:
  hash: "$2y$12$K/SpwjtB.wOHJ/Nc6GVRDuc1h0rM1DfvziFRNPtk27P.c4yDr9njO"
  reserved: true
  backend_roles:
  - "admin"
  description: "Demo admin user"
...

#kibanaserver user
...
kibanaserver:
  hash: "$2a$12$4AcgAt3xwOWadA5s5blL6ev39OXDNhmOesEoo33eZtrq2N0YrU3H."
  reserved: true
  description: "Demo kibanaserver user"
...
