# Setting up File Integrity Monitoring (FIM) in Wazuh

## Step 1: Open the Wazuh Agent Configuration File

#1. Locate the configuration file for your Wazuh agent. The path to the configuration file depends on your operating system:
   - Linux: `/var/ossec/etc/ossec.conf`

## Step 2: Enable File Integrity Monitoring

##1. In the configuration file, locate the `<syscheck>` section, which is where FIM settings are configured.
##2. Ensure that the `<disabled>` element is set to `<disabled>no</disabled>`. This enables FIM monitoring. If it's already set to "no," you can skip this step.

## Step 3: Configure Real-time Monitoring and recording of file attributes

##1. To enable real-time monitoring of a directory, add the following lines within the `<syscheck>` section. Replace `FILEPATH/OF/MONITORED/DIRECTORY` with the actual directory path you want to monitor in real-time.

<directories check_all="no" check_mtime="yes">FILEPATH/OF/MONITORED/DIRECTORY</directories>

## Step 4: Restart the Wazuh Agent
systemctl restart wazuh-agent

# Trigger alerts when execute permission is added to a script

## Step 1: Create a Custom Rule on the Wazuh Server
## Create a custom rule file for the FIM rule using a text editor:
touch /var/ossec/etc/rules/fim_specialdir3.xml

## Open the custom rule file for editing:
nano /var/ossec/etc/rules/fim_specialdir3.xml

## Add the following rule definition to the file. This rule triggers an alert when execute permission is added to a shell script (with a .sh extension) in a monitored directory:

<group name="syscheck">
  <rule id="100002" level="8">
    <if_sid>550</if_sid>
    <field name="file">\.sh$</field>
    <field name="changed_fields">^permission$</field>
    <field name="perm" type="pcre2">\w\wx</field>
    <description>Execute permission added to shell script.</description>
    <mitre>
      <id>T1222.002</id>
    </mitre>
  </rule>
</group>

## Restart the Wazuh manager to apply the configuration changes:
systemctl restart wazuh-manager

## Step 2: Configure the Wazuh Agent on the Endpoint

##SSH into your Ubuntu 20.04 endpoint.
##Create the monitored directory (/specialdir3):
mkdir /specialdir3

##Edit the Wazuh agent configuration file:
nano /var/ossec/etc/ossec.conf

##Add the directory (/specialdir3) to the syscheck section for monitoring:

<syscheck>
   <directories realtime="yes">/specialdir3</directories>
</syscheck>
Save the file and exit the text editor.

##Restart the Wazuh agent to apply the configuration changes:

systemctl restart wazuh-agent

##Step 3: Test the Configuration

##Create a shell script file (e.g., fim.sh) in the monitored directory (/specialdir3):
touch /specialdir3/fim.sh

##Add execute permission to the script:
chmod +x /specialdir3/fim.sh






