# Setting up File Integrity Monitoring (FIM) in Wazuh

## Step 1: Open the Wazuh Agent Configuration File

1. Locate the configuration file for your Wazuh agent. The path to the configuration file depends on your operating system:
   - Linux: `/var/ossec/etc/ossec.conf`
   - Windows: `C:\Program Files (x86)\ossec-agent\ossec.conf`
   - macOS: `/Library/Ossec/etc/ossec.conf`

## Step 2: Enable File Integrity Monitoring

1. In the configuration file, locate the `<syscheck>` section, which is where FIM settings are configured.
2. Ensure that the `<disabled>` element is set to `<disabled>no</disabled>`. This enables FIM monitoring. If it's already set to "no," you can skip this step.

## Step 3: Configure Real-time Monitoring

1. To enable real-time monitoring of a directory, add the following lines within the `<syscheck>` section. Replace `FILEPATH/OF/MONITORED/DIRECTORY` with the actual directory path you want to monitor in real-time.

```xml
<directories realtime="yes">FILEPATH/OF/MONITORED/DIRECTORY</directories>

