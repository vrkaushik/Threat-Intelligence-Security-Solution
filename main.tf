# Specify the provider and authentication details
provider "google" {
  credentials = file("<PATH_TO_YOUR_GCP_SERVICE_ACCOUNT_KEY_FILE>")
}

######################################--------OpenCTI VPC--------######################################
resource "google_compute_network" "vpc_network" {
  name                    = "opencti-vpc"
  auto_create_subnetworks = true
}

# # Create a subnet within the VPC network
# resource "google_compute_subnetwork" "subnet" {
#   name          = "opencti-network"
#   ip_cidr_range = "10.0.1.0/24"
#   region        = var.region
#   network       = google_compute_network.vpc_network.name
# }

# Firewall Rules for OpenCTI 
resource "google_compute_firewall" "opencti_allow_wazuh" {
    name = "opencti_allow_wazuh"
    network = "opencti-vpc"

    allow {
        protocol =  "tcp"
        ports = ["1514", "1515"]        
    }

    #source_ranges = [google_compute_instance.wazuh.network_interface.0.network_ip]  
    source_tags = ["wazuh"]
    target_tags = ["opencti"]
}

resource "google_compute_firewall" "opencti_allow_ssh" {
  name = "opencti_allow_ssh"
  network = "opencti-vpc"
  
  allow {
    protocol = "tcp"
    ports = ["33333"]
  }

  source_ranges = [google_compute_instance.bastion.network_interface.0.network_ip]  
  target_tags = ["opencti"]
}

resource "google_compute_firewall" "opencti_allow_http" {
  name = "opencti_allow_ssh"
  network = "opencti-vpc"
  
  allow {
    protocol = "tcp"
    ports = ["8080"]
  }

  #source_ranges = [google_compute_instance.bastion.network_interface.0.network_ip]  
  source_tags = ["opencti"]
  target_tags = ["opencti"]
}

resource "google_compute_firewall" "opencti_allow_es" {
  name = "opencti_allow_es"
  network = "opencti-vpc"
  
  allow {
    protocol = "tcp"
    ports = ["443","9000"]
  }

  source_ranges = ["0.0.0.0/0"]  
  target_tags = ["opencti"]
}


######################################--------OpenCTI--------######################################


# Reserve a static external IP address for OpenCTI
resource "google_compute_address" "opencti_static_ip" {
  name   = "opencti-static-ip"
  region = var.region
}


# Create a GCP instance within the specified subnet and with the reserved static IP
# OpenCTI instance
resource "google_compute_instance" "vm_instance" {
  name         = "opencti-instance"
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
    network = google_compute_network.vpc_network.self_link
    subnetwork = google_compute_subnetwork.subnet.self_link
    access_config {
      nat_ip = google_compute_address.opencti_static_ip.address
    }
  }
  tags = ["opencti"]
}




#Firewall Rules for Wazuh

resource "google_compute_firewall" "wazuh_allow_ssh" {
  name = "wazuh_allow_ssh"
  network = "opencti-vpc"
  
  allow {
    protocol = "tcp"
    ports = ["33333"]
  }

  source_ranges = [google_compute_instance.bastion.network_interface.0.network_ip]  
  target_tags = ["wazuh"]
}


resource "google_compute_firewall" "wazuh_allow_agents" {
  name = "wazuh_allow_agents"
  network = "opencti-vpc"
  
  allow {
    protocol = "tcp"
    ports = ["1514","1515", "1516","9200","9300-9400","55000"]
  }

  source_ranges = [google_compute_instance.bastion.network_interface.0.network_ip]  
  source_tags = ["opencti"]
  target_tags = ["wazuh"]
}

resource "google_compute_firewall" "wazuh_allow_https" {
  name = "wazuh_allow_https"
  network = "opencti-vpc"
  
  allow {
    protocol = "tcp"
    ports = ["443"]
  }

  source_ranges = ["0.0.0.0/0"]  
  target_tags = ["wazuh"]
}

######################################--------Wazuh--------######################################

# Reserve a static external IP address for Wazuh
resource "google_compute_address" "wazuh_static_ip" {
  name   = "wazuh_static_ip"
  region = var.region
}

# Wazuh Instance
resource "google_compute_instance" "vm_instance" {
  name         = "opencti-instance"
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
    network = google_compute_network.vpc_network.self_link
    subnetwork = google_compute_subnetwork.subnet.self_link
    access_config {
      nat_ip = google_compute_address.wazuh_static_ip.address
    }
  }
 tags = ["wazuh"]
}



######################################--------Bastion VPC--------######################################
resource "google_compute_network" "bastion_vpc" {
  name                    = "bastion_vpc"
  auto_create_subnetworks = false
}

# Create a subnet within the VPC network
# resource "google_compute_subnetwork" "subnet" {
#   name          = "opencti_network"
#   ip_cidr_range = "10.0.1.0/24"
#   region        = var.region
#   network       = google_compute_network.vpc_network.name
# }

# Firewall Rules
resource "google_compute_firewall" "bastion_allow_wazuh" {
    name = "bastion_allow_wazuh"
    network = "bastion_vpc"

    allow {
        protocol =  "tcp"
        ports = ["1514", "1515"]        
    }

    source_ranges = [google_compute_instance.wazuh.network_interface.0.network_ip]  
    target_tags = ["bastion"]
}

resource "google_compute_firewall" "bastion_allow_ssh" {
  name = "bastion_allow_ssh"
  network = "bastion_vpc"
  
  allow {
    protocol = "tcp"
    ports = ["33333"]
  }

  source_ranges = ["0.0.0.0/0"]
  target_tags = "bastion"
}

######################################--------Bastion--------######################################

# Reserve a static external IP address for Bastion Host
resource "google_compute_address" "bastion_static_ip" {
  name   = "bastion-static-ip"
  region = var.region
}

resource "google_compute_instance" "bastion" {
    name = "bastion"
    machine_type = "e2-medium"
    zone = "us-east1"
    
    boot_disk {
      initialize_params {
        image = "debian-11-bullseye-v20231010"
        size = 10
      }
    }
    network_interface {
    network = google_compute_network.vpc_network.self_link
    subnetwork = google_compute_subnetwork.subnet.self_link
    access_config {
      nat_ip = google_compute_address.bastion_static_ip.address
    }
  }

    tags = ["bastion"]
}




