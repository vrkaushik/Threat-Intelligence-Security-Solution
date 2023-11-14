# Specify the provider and authentication details
provider "google" {
  credentials = file("gcp-cred.json")
  project = var.project_id
}

# OpenCTI

# OpenCTI VPC
resource "google_compute_network" "opencti-vpc" {
  name = "opencti-vpc"
  auto_create_subnetworks = true
}

# Firewall Rules for OpenCTI 

# Allow TCP ports 1514 and 1515 from Wazuh
resource "google_compute_firewall" "opencti-allow-wazuh" {
    name = "opencti-allow-wazuh"
    network = google_compute_network.opencti-vpc.name

    allow {
        protocol =  "tcp"
        ports = ["1514", "1515"]        
    }
 
    source_tags = ["wazuh"]
    target_tags = ["opencti"] 
}

# During provisioning, allow TCP on port 22 from any
resource "google_compute_firewall" "opencti-allow-ssh-provisioning" {
  name = "opencti-allow-ssh-provisioning"
  network = google_compute_network.opencti-vpc.name
  
  allow {
    protocol = "tcp"
    ports = ["22"]
  }

  source_ranges = ["0.0.0.0/0"]
  target_tags = ["opencti"]

  count = var.provisioned ? 0 : 1
}

# After provisioning, allow TCP on port 33333 from Bastion
resource "google_compute_firewall" "opencti-allow-ssh" {
  name = "opencti-allow-ssh"
  network = google_compute_network.opencti-vpc.name
  
  allow {
    protocol = "tcp"
    ports = ["33333"]
  }

  source_ranges = [google_compute_instance.bastion.network_interface.0.access_config.0.nat_ip]
  target_tags = ["opencti"]

  count = var.provisioned ? 1 : 0
}

# Allow TCP port 8080 within OpenCTI
resource "google_compute_firewall" "opencti-allow-http" {
  name = "opencti-allow-http"
  network = google_compute_network.opencti-vpc.name
  
  allow {
    protocol = "tcp"
    ports = ["8080"]
  }

  source_tags = ["opencti"]
  target_tags = ["opencti"]
}

# Allow ports 443 and 9000 from any source to OpenCTI
resource "google_compute_firewall" "opencti-allow-es" {
  name = "opencti-allow-es"
  network = google_compute_network.opencti-vpc.name
  
  allow {
    protocol = "tcp"
    ports = ["443","9000"]
  }

  source_ranges = ["0.0.0.0/0"]  
  target_tags = ["opencti"]
}

# Reserve a static external IP address for OpenCTI
resource "google_compute_address" "opencti_static_ip" {
  name = "opencti-static-ip"
  region = var.region
}

# Provision OpenCTI machine
resource "google_compute_instance" "opencti" {
  name = "opencti"
  machine_type = "e2-highmem-4"
  zone = var.zone
  project = var.project_id

  boot_disk {
    initialize_params {
      image = "debian-11-bullseye-v20231004"
      size = 60
    }
  }

  network_interface {
    network = google_compute_network.opencti-vpc.self_link
    access_config {
      nat_ip = google_compute_address.opencti_static_ip.address
    }
  }

  metadata = {
    ssh-keys = "admin:${file(var.public_key)}"
  }

  connection {
    type = "ssh"
    host = google_compute_address.opencti_static_ip.address
    user = "admin"
    private_key = file(var.private_key)
  }

  # Copy OpenCTI setup script
  provisioner "file" {
    destination = "/home/admin/opencti-deps.sh"
    content = templatefile("opencti-deps.sh", {
      wazuh_external_ip = google_compute_address.wazuh_static_ip.address,
      wazuh_internal_ip = google_compute_instance.wazuh.network_interface.0.network_ip, 
      docker_compose_file = file("opencti/docker-compose.yml"),
      nginx_conf_file = file("opencti/nginx/conf.d/default.conf")
    })
  }

  # Copy docker compose
  provisioner "file" {
    source = "opencti/docker-compose.yml"
    destination = "/home/admin/docker-compose.yml"
  }

  # Copy nginx config
  provisioner "file" {
    source = "opencti/nginx/conf.d/default.conf"
    destination = "/home/admin/default.conf"
  }

  # Copy SSH config
  provisioner "file" {
    source = "opencti/ssh/sshd_config"
    destination = "/home/admin/sshd_config"
  }


  # Execute setup script
  provisioner "remote-exec" {
    inline = ["/bin/bash /home/admin/opencti-deps.sh"]
  }

  tags = ["opencti"]
}

# Wazuh

# Wazuh Firewall Rules

# During provisoning, allow TCP on port 22 from any
resource "google_compute_firewall" "wazuh-allow-ssh-provisioning" {
  name = "wazuh-allow-ssh-provisioning"
  network = google_compute_network.opencti-vpc.name
  
  allow {
    protocol = "tcp"
    ports = ["22"]
  }

  source_ranges = ["0.0.0.0/0"]
  target_tags = ["wazuh"]

  count = var.provisioned ? 0 : 1
}

# After provisioning, allow TCP on port 33333 (SSH) from Bastion
resource "google_compute_firewall" "wazuh-allow-ssh" {
  name = "wazuh-allow-ssh"
  network = google_compute_network.opencti-vpc.name
  
  allow {
    protocol = "tcp"
    ports = ["33333"]
  }

  source_ranges = [google_compute_instance.bastion.network_interface.0.access_config.0.nat_ip]
  target_tags = ["wazuh"]

  count = var.provisioned ? 1 : 0
}

# Allow TCP on ports 1514, 1515, 1516, 9200, 9300-9400, and 55000 from OpenCTI and Basiton
resource "google_compute_firewall" "wazuh-allow-agents" {
  name = "wazuh-allow-agents"
  network = google_compute_network.opencti-vpc.name
  
  allow {
    protocol = "tcp"
    ports = ["1514","1515","1516","9200","9300-9400","55000"]
  }

  source_ranges = [google_compute_instance.bastion.network_interface.0.access_config.0.nat_ip]
  source_tags = ["opencti"]
  target_tags = ["wazuh"]
}

# Allow TCP on port 443 from any
resource "google_compute_firewall" "wazuh-allow-https" {
  name = "wazuh-allow-https"
  network = google_compute_network.opencti-vpc.name
  
  allow {
    protocol = "tcp"
    ports = ["443"]
  }

  source_ranges = ["0.0.0.0/0"]
  target_tags = ["wazuh"]
}

# Reserve a static external IP address for Wazuh
resource "google_compute_address" "wazuh_static_ip" {
  name   = "wazuh-static-ip"
  region = var.region
}

# Provision Wazuh Instance
resource "google_compute_instance" "wazuh" {
  name = "wazuh"
  machine_type = "e2-medium"
  zone = var.zone
  project = var.project_id

  boot_disk {
    initialize_params {
      image = "ubuntu-2204-jammy-v20230919"
      size = 50
    }
  }

  network_interface {
    network = google_compute_network.opencti-vpc.self_link
    access_config {
      nat_ip = google_compute_address.wazuh_static_ip.address
    }
  }

  metadata = {
    ssh-keys = "ubuntu:${file(var.public_key)}"
  }

  connection {
    type = "ssh"
    host = google_compute_address.wazuh_static_ip.address
    user = "ubuntu"
    private_key = file(var.private_key)
  }

  # Copy OpenCTI setup script
  provisioner "file" {
    destination = "/home/ubuntu/wazuh-deps.sh"
    source = "wazuh-deps.sh"
  }

  # provisioner "file" {
  #   source = "users.txt"
  #   destination = "/home/ubuntu/users.txt"
  # }

  # provisioner "file" {
  #   source = "usergen.sh"
  #   destination = "/home/ubuntu/usergen.sh"
  # }

  # Copy docker compse
  provisioner "file" {
    source = "wazuh/docker-compose.yml"
    destination = "/home/ubuntu/docker-compose.yml"
  }

  # Copy SSH config
  provisioner "file" {
    source = "wazuh/ssh/sshd_config"
    destination = "/home/ubuntu/sshd_config"
  }

  #Wazuh Additional capabilities
  #Copy ossec.conf
  provisioner "file" {
    source = "wazuh/configs/ossec.conf"
    destination = "/home/ubuntu/wazuh_configs/ossec.conf"
  }

  # Copy /var/ossec/etc/rules/fim_specialdir3.xml
  provisioner "file" {
    source = "wazuh/configs/fim_specialdir3.xml"
    destination = "/home/ubuntu/wazuh_configs/fim_specialdir3.xml"
  }

  # Copy malware hashes
  provisioner "file" {
    source = "wazuh/configs/malware-hashes"
    destination = "/home/ubuntu/wazuh_configs/malware-hashes"
  }

  #Copy /var/ossec/etc/rules/local_rules.xml 
  provisioner "file" {
    source = "wazuh/configs/local_rules.xml"
    destination = "/home/ubuntu/wazuh_configs/local_rules.xml"
  }

  #Copy /var/ossec/etc/shared/default/agent.conf
  provisioner "file" {
    source = "wazuh/configs/agent.conf"
    destination = "/home/ubuntu/wazuh_configs/agent.conf"
  }

  #Copy /var/ossec/etc/decoders/local_decoder.xml decoder
  provisioner "file" {
    source = "wazuh/configs/local_decoder.xml"
    destination = "/home/ubuntu/wazuh_configs/local_decoder.xml"
  }

  # Execute setup script
  provisioner "remote-exec" {
    inline = ["/bin/bash /home/ubuntu/wazuh-deps.sh"]
  }

  # provisioner "remote-exec" {
  #   inline = ["/bin/bash /home/ubuntu/usergen.sh"]
  # }
  
  tags = ["wazuh"]
  depends_on = [google_compute_instance.bastion]
}

# Bastion

# Bastion VPC
resource "google_compute_network" "bastion-vpc" {
  name = "bastion-vpc"
  auto_create_subnetworks = true
}

# Bastion Firewall Rules

# Allow TCP ports 1514 and 1515 from Wazuh
resource "google_compute_firewall" "bastion-allow-wazuh" {
    name = "bastion-allow-wazuh"
    network = google_compute_network.bastion-vpc.name

    allow {
        protocol =  "tcp"
        ports = ["1514", "1515"]        
    }

    source_ranges = [google_compute_instance.wazuh.network_interface.0.access_config.0.nat_ip]
    target_tags = ["bastion"]
}

# During provisioning, allow TCP port 22 from any
resource "google_compute_firewall" "bastion-allow-ssh-provisioning" {
  name = "bastion-allow-ssh-provisioning"
  network = google_compute_network.bastion-vpc.name
  direction = "INGRESS"

  allow {
    protocol = "tcp"
    ports = ["22"]
  }

  source_ranges = ["0.0.0.0/0"]
  target_tags = ["bastion"]

  count = var.provisioned ? 0 : 1  # Conditionally create the rule based on the variable
}

# After provisioning, allow TCP on port 33333 from any
resource "google_compute_firewall" "bastion-allow-ssh" {
  name = "bastion-allow-ssh"
  network = google_compute_network.bastion-vpc.name
  direction = "INGRESS"

  allow {
    protocol = "tcp"
    ports = ["33333"]
  }

  source_ranges = ["0.0.0.0/0"]
  target_tags = ["bastion"]

  count = var.provisioned ? 1 : 0  # Conditionally create the rule based on the variable
}

# Reserve a static external IP address for Bastion Host
resource "google_compute_address" "bastion_static_ip" {
  name = "bastion-static-ip"
  region = var.region
}

# Provision Bastion machine
resource "google_compute_instance" "bastion" {
  name = "bastion"
  machine_type = "e2-medium"
  zone = var.zone
  
  boot_disk {
    initialize_params {
      image = "debian-11-bullseye-v20231010"
      size = 10
    }
  }

  network_interface {
    network = google_compute_network.bastion-vpc.self_link
    access_config {
      nat_ip = google_compute_address.bastion_static_ip.address
    }
  }

  metadata = {
    ssh-keys = "admin:${file(var.public_key)}"
  }

  connection {
    type = "ssh"
    host = google_compute_address.bastion_static_ip.address
    user = "admin"
    private_key = file(var.private_key)
  }

  # Copy setup script
  provisioner "file" {
    destination = "/home/admin/bastion-deps.sh"
    content = templatefile("bastion-deps.sh", {
      wazuh_external_ip = google_compute_address.wazuh_static_ip.address
    })
  }

  # Copy SSH config
  provisioner "file" {
    source = "bastion/ssh/sshd_config"
    destination = "/home/admin/sshd_config"
  }

  # Execute setup script
  provisioner "remote-exec" {
    inline = ["/bin/bash /home/admin/bastion-deps.sh"]
  }
  
  tags = ["bastion"]
}
