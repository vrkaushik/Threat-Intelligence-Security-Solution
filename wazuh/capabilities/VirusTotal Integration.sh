#add the below configuration block in the /var/ossec/etc/ossec.conf file of Wazuh-Manager

<!-- VirusTotal Integration
  <integration>
    <name>virustotal</name>
    <api_key>b2d8e9f22c90aa5a569f54cf6e90ed31322c93386d195900f4c135f52e290976</api_key> <!-- Replace with your VirusTotal API >
    <group>syscheck</group>
    <alert_format>json</alert_format>
  </integration>
