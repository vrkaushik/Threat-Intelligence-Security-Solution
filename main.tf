# Specify the provider and authentication details
provider "google" {
  credentials = file("gcp-cred2.json")
  project = "capstone-stuxnet-2"
}

######################################--------OpenCTI VPC--------######################################
resource "google_compute_network" "opencti-vpc" {
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
resource "google_compute_firewall" "opencti-allow-wazuh" {
    name = "opencti-allow-wazuh"
    network = google_compute_network.opencti-vpc.name

    allow {
        protocol =  "tcp"
        ports = ["1514", "1515"]        
    }

    #source_ranges = [google_compute_instance.wazuh.network_interface.0.network_ip]  
    source_tags = ["wazuh"]
    target_tags = ["opencti"] 
}

resource "google_compute_firewall" "opencti-allow-ssh" {
  name = "opencti-allow-ssh"
  network = google_compute_network.opencti-vpc.name
  
  allow {
    protocol = "tcp"
    ports = ["33333"]
  }

  source_ranges = [google_compute_instance.bastion.network_interface.0.network_ip]  
  target_tags = ["opencti"]
}

resource "google_compute_firewall" "opencti-allow-http" {
  name = "opencti-allow-http"
  network = google_compute_network.opencti-vpc.name
  
  allow {
    protocol = "tcp"
    ports = ["8080"]
  }

  #source_ranges = [google_compute_instance.bastion.network_interface.0.network_ip]  
  source_tags = ["opencti"]
  target_tags = ["opencti"]
}

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


######################################--------OpenCTI--------######################################


# Reserve a static external IP address for OpenCTI
resource "google_compute_address" "opencti_static_ip" {
  name   = "opencti-static-ip"
  region = var.region
}


# Create a GCP instance within the specified subnet and with the reserved static IP
# OpenCTI instance
resource "google_compute_instance" "opencti-instance" {
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
    network = google_compute_network.opencti-vpc.self_link
    # subnetwork = google_compute_subnetwork.subnet.self_link
    access_config {
      nat_ip = google_compute_address.opencti_static_ip.address
    }
  }
  tags = ["opencti"]
}




#Firewall Rules for Wazuh

resource "google_compute_firewall" "wazuh-allow-ssh" {
  name = "wazuh-allow-ssh"
  network = google_compute_network.opencti-vpc.name
  
  allow {
    protocol = "tcp"
    ports = ["33333"]
  }

  source_ranges = [google_compute_instance.bastion.network_interface.0.network_ip]  
  target_tags = ["wazuh"]
}


resource "google_compute_firewall" "wazuh-allow-agents" {
  name = "wazuh-allow-agents"
  network = google_compute_network.opencti-vpc.name
  
  allow {
    protocol = "tcp"
    ports = ["1514","1515", "1516","9200","9300-9400","55000"]
  }

  source_ranges = [google_compute_instance.bastion.network_interface.0.network_ip]  
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

######################################--------Wazuh--------######################################

# Reserve a static external IP address for Wazuh
resource "google_compute_address" "wazuh-static-ip" {
  name   = "wazuh-static-ip"
  region = var.region
}

# Wazuh Instance
resource "google_compute_instance" "wazuh-instance" {
  name         = "wazuh-instance"
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
    # subnetwork = google_compute_subnetwork.subnet.self_link
    access_config {
      nat_ip = google_compute_address.wazuh-static-ip.address
    }
  }
 tags = ["wazuh"]
}



######################################--------Bastion VPC--------######################################
resource "google_compute_network" "bastion-vpc" {
  name                    = "bastion-vpc"
  auto_create_subnetworks = true
}

# Create a subnet within the VPC network
# resource "google_compute_subnetwork" "subnet" {
#   name          = "opencti_network"
#   ip_cidr_range = "10.0.1.0/24"
#   region        = var.region
#   network       = google_compute_network.vpc_network.name
# }

# Firewall Rules
resource "google_compute_firewall" "bastion-allow-wazuh" {
    name = "bastion-allow-wazuh"
    network = google_compute_network.bastion-vpc.name

    allow {
        protocol =  "tcp"
        ports = ["1514", "1515"]        
    }

    source_ranges = [google_compute_instance.wazuh-instance.network_interface.0.network_ip]  
    target_tags = ["bastion"]
}

resource "google_compute_firewall" "bastion-allow-ssh" {
  name = "bastion-allow-ssh"
  network = google_compute_network.bastion-vpc.name
  
  allow {
    protocol = "tcp"
    ports = ["33333"]
  }

  source_ranges = ["0.0.0.0/0"]
  target_tags = ["bastion"]
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
    zone = var.zone
    
    boot_disk {
      initialize_params {
        image = "debian-11-bullseye-v20231010"
        size = 10
      }
    }
    network_interface {
    network = google_compute_network.bastion-vpc.self_link
    # subnetwork = google_compute_subnetwork.subnet.self_link
    access_config {
      nat_ip = google_compute_address.bastion_static_ip.address
    }
  }

    tags = ["bastion"]
}




