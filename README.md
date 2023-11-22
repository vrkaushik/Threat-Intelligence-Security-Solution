# Team Stuxnet 
This repository contains our implementation of a secure deployment of OpenCTI as a capstone project. This project includes [OpenCTI](https://github.com/OpenCTI-Platform/opencti), which is an open-source threat intelligence platform, with security monitoring through [Wazuh](https://wazuh.com/), and Terraform scripts to deploy the project through Google Cloud Platform (GCP).

## Architecture
The project uses 3 VM instances: a bastion host, OpenCTI, and Wazuh. These VMs are split into 2 VPC: one for a bastion host, and the other for OpenCTI and Wazuh. 

The bastion host is used to regulate SSH access to OpenCTI and Wazuh. Firewall rules are configured such that administrators must SSH into the bastion and forward their agent to SSH into OpenCTI and Wazuh.

The OpenCTI machine runs all components necessary for OpenCTI to function. See the full architecture for OpenCTI [here](https://docs.opencti.io/latest/deployment/overview/#architecture). In addition to the existing architecture, this project inclues an `nginx` reverse proxy that serves OpenCTI over HTTPS instead of HTTP.

The Wazuh machine runs the Wazuh server that performs security monitoring. Specifically, this project uses the following Wazuh capabilities:

- File Integrity Monitoring: FIM monitors files and directories and triggers an alert when a user or process creates, modifies, and deletes monitored files. It runs a baseline scan, storing the cryptographic checksum and other attributes of the monitored files. Made changes to the conf to ignore certain file types to reduce the number of false positives. A custom rule was also created to trigger an alert when execute permission is added to a shell script. The below image shows the alert generated when the FIM module detects the addition of execute permission to the shell script.

- Malware Detection: Created custom rules based on file creation and modification events to detect specific malware. Created a CBD list of malware hashes and created a rule to generate alerts when the Wazuh analysis engine matches the MD5 hash of a new or modified file to a hash in the CDB list.

- Vulnerability Management: Enabled the Vulnerability Detection capability by editing the wazuh-manager configuration file. Configured the agent.conf file to enable the Syscollector module to collect system information, including installed packages and hotfixes.

- Container Security: Enabled the Wazuh Docker listener on the Agent by adding a block of code to the ossec.conf file present on the agent.

- VirusTotal Integration with Wazuh. This integration allows the inspection of malicious files using the VirusTotal database.

Wazuh agents are installed on the bastion and OpenCTI machines to enable these capabilities.

## How to use
This project requires some external setup:
1. Create a new project in [GCP](https://console.cloud.google.com/home/dashboard).
2. Navigate to IAM & Admin > Service Accounts > Create Service Account to create a service account for the project. Select the Compute Admin role and finish creating the account.
3. Select the service account > Keys > Add Key > Create New Key > JSON > Create. Rename the downloaded credentials to `gcp-cred.json` and move to the root of the project directory.
4. Navigate to APIs & Services > Library. Search "Compute Engine API" and enable the API. This may take a few minutes.
5.  Update the following variables in `variables.tf`:
    - `projct_id`: the name of the project you created
    - `private_key`: the path to the private key to provide SSH access to the project
    - `public_key`: the path to the public key to provide SSH access to the project
6. Install [`Terraform`](https://developer.hashicorp.com/terraform/install) if not already installed.
7. Run the command `terraform apply` and confirm by typing "yes". This will provision all resources for the project. Provisioning will take several minutes. Note the IP addresses to access your project that are printed after provisioning. NOTE: this will start to incur costs in your GCP account.
8. Once Terraform is done provisioning, run the command `terraform apply -var="provisioned=true"`. This is to amend some firewall rules that were necessary during provisioning.

The machines are now accessible at the printed IP addresses. OpenCTI and Wazuh may take a couple minutes to fully start their services.

### SSH
To SSH into the machines, you must first SSH into bastion with agent forwarding enabled. To do so, first enable your SSH agent on your local machine. Then, SSH into bastion with the following command: `ssh -A -p 33333 admin@<bastion-ip>`.

To SSH into OpenCTI, then run `ssh -A -p 33333 admin@<opencti-ip>`.

To SSH into Wazuh, then run `ssh -A -p 33333 ubuntu@<wazuh-ip>`.

### Credentials
The default credentials for OpenCTI are admin@opencti.io:Stuxnet@123#. We highly recommend either editing these credentials in `opencti-deps.sh` (`OPENCTI_ADMIN_EMAIL` and `OPENCTI_ADMIN_PASSWORD`) or enabling OAuth through Github.

To enable OAuth through Github:
1. In your Github acount, go to Settings > Developer Settings > OAuth Apps > Register a new application. 
2. Fill out an appropriate Application name and description. Set the Homepage URL to `https://<opencti-ip>`. Set the Authorization callback URL to `https://<opencti-ip>/auth/github/callback`.
3. Generate a new client secret. Make sure to save the secret.
4. SSH into the OpenCTI machine as explained above. Pause OpenCTI by running `docker-compose down`. 
5. In `docker-compose.yml`, comment out the existing `PROVIDERS__LOCAL__STRATEGY` and `PROVIDERS__LOCAL__CONFIG__DISABLED` environment variables for the `opencti` service and add the following lines.
    ```- PROVIDERS__GITHUB__IDENTIFIER=github
    - PROVIDERS__GITHUB__STRATEGY=GithubStrategy
    - PROVIDERS__GITHUB__CONFIG__CLIENT_ID=<YOUR-CLIENT-ID>
    - PROVIDERS__GITHUB__CONFIG__CLIENT_SECRET=<YOUR-SECRET>
    - PROVIDERS__GITHUB__CONFIG__CALLBACK_URL=https://<opencti-ip>/auth/github/callback
    - PROVIDERS__LOCAL__STRATEGY=LocalStrategy
    - PROVIDERS__LOCAL__CONFIG__DISABLED=true
6. Restart OpenCTI by running `docker-compose up -d`.

OpenCTI should now enable authentication through Github.