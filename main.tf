# Specify the provider and authentication details
provider "google" {
  credentials = file("gcp-cred.json")
  project = var.project_id
}

# OpenCTI

# OpenCTI VPC
resource "google_compute_network" "opencti-vpc" {
  name                    = "opencti-vpc"
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
    #source_ranges = [google_compute_instance.wazuh.network_interface.0.network_ip]  
    target_tags = ["opencti"] 
}

# Allow TCP port 33333 (SSH) from Bastion
resource "google_compute_firewall" "opencti-allow-ssh" {
  name = "opencti-allow-ssh"
  network = google_compute_network.opencti-vpc.name
  
  allow {
    protocol = "tcp"
    # ports = ["33333"]
    ports = ["22"]
  }

  #source_ranges = [google_compute_instance.bastion.network_interface.0.network_ip]  
  source_ranges = ["0.0.0.0/0"]
  target_tags = ["opencti"]
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
  name   = "opencti-static-ip"
  region = var.region
}

# Provision OpenCTI machine
resource "google_compute_instance" "opencti" {
  name         = "opencti"
  machine_type = "e2-highmem-4"
  zone         = var.zone
  project      = var.project_id

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
    destination = "/home/admin/deps.sh"
    content = templatefile("deps.sh", {
      wazuh_external_ip     = google_compute_address.wazuh_static_ip.address,
      wazuh_internal_ip = google_compute_instance.wazuh.network_interface.0.network_ip, 
      docker_compose_file   = file("opencti/docker-compose.yml"),
      nginx_conf_file       = file("opencti/nginx/conf.d/default.conf")
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

  # Execute setup script
  provisioner "remote-exec" {
    inline = ["/bin/bash /home/admin/deps.sh"]
  }

  tags = ["opencti"]
}

# Wazuh

# Wazuh Firewall Rules

# Allow TCP on port 33333 (SSH) from bastion
resource "google_compute_firewall" "wazuh-allow-ssh" {
  name = "wazuh-allow-ssh"
  network = google_compute_network.opencti-vpc.name
  
  allow {
    protocol = "tcp"
    # ports = ["33333"]
    ports = ["22"]
  }

  #source_ranges = [google_compute_instance.bastion.network_interface.0.network_ip]  
  source_ranges =["0.0.0.0/0"]
  target_tags = ["wazuh"]
}


resource "google_compute_firewall" "wazuh-allow-agents" {
  name = "wazuh-allow-agents"
  network = google_compute_network.opencti-vpc.name
  
  allow {
    protocol = "tcp"
    ports = ["1514","1515", "1516","9200","9300-9400","55000"]
  }

  source_ranges = [google_compute_instance.bastion.network_interface.0.access_config.0.nat_ip]  
  source_tags = ["opencti"]
  target_tags = ["wazuh"]
}

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

# Wazuh

# Reserve a static external IP address for Wazuh
resource "google_compute_address" "wazuh_static_ip" {
  name   = "wazuh-static-ip"
  region = var.region
}

# Provision Wazuh Instance
resource "google_compute_instance" "wazuh" {
  name         = "wazuh"
  machine_type = "e2-medium"
  zone         = var.zone
  project      = var.project_id

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

  provisioner "file" {
    source = "users.txt"
    destination = "/home/ubuntu/users.txt"
  }

  provisioner "file" {
    source = "usergen.sh"
    destination = "/home/ubuntu/usergen.sh"
  }

  # Copy docker compse
  provisioner "file" {
    source = "wazuh/docker-compose.yml"
    destination = "/home/ubuntu/docker-compose.yml"
  }

  # Execute setup script
  provisioner "remote-exec" {
    inline = ["/bin/bash /home/ubuntu/wazuh-deps.sh"]
  }

  provisioner "remote-exec" {
    inline = ["/bin/bash /home/ubuntu/usergen.sh"]
  }
  
  tags = ["wazuh"]
}

# Bastion

# Bastion VPC
resource "google_compute_network" "bastion-vpc" {
  name                    = "bastion-vpc"
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

# Allow TCP port 33333 (SSH) from any
resource "google_compute_firewall" "bastion-allow-ssh" {
  name = "bastion-allow-ssh"
  network = google_compute_network.bastion-vpc.name
  
  allow {
    protocol = "tcp"
    ports = ["22"]
  }

  source_ranges = ["0.0.0.0/0"]
  target_tags = ["bastion"]
}

# Reserve a static external IP address for Bastion Host
resource "google_compute_address" "bastion_static_ip" {
  name   = "bastion-static-ip"
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
    # private_key = file("id_ed25519.key")
    private_key = file(var.private_key)
  }

  # Copy setup script
  provisioner "file" {
    destination = "/home/admin/bastion-deps.sh"
    content = templatefile("bastion-deps.sh", {
      wazuh_external_ip     = google_compute_address.wazuh_static_ip.address
     })
  }

  # Execute setup script
  provisioner "remote-exec" {
    inline = ["/bin/bash /home/admin/bastion-deps.sh"]
  }
  
  tags = ["bastion"]
}
