resource "google_compute_address" "bastion_ip" {
    name = "bastion_ip"
}

resource "google_compute_firewall" "bastion-allow-wazuh" {
    name = "bastion-allow-wazuh"
    network = "bastion"

    allow {
        protocol =  "tcp"
        ports = ["1514", "1515"]        
    }

    source_ranges = [google_compute_instance.default.network_interface.0.network_ip]  
    target_tags = ["bastion"]
}

resource "google_compute_firewall" "bastion-allow-ssh" {
  name = "bastion-allow-ssh"
  network = "bastion"
  
  allow {
    protocol = "tcp"
    ports = ["33333"]
  }

  target_tags = "bastion"
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

    tags = ["bastion"]
    
    metadata_startup_script = <<-EOF
      #!/bin/bash

      # copy SSH config
      echo "${file("bastion/sshd_config")} > /etc/ssh/sshd_config
      systemctl restart sshd

      echo "${file("users.txt")}" > /temp/users.txt
      while IFS= read -r username;
      do
          # generate user
          if id "$username" &>/dev/null; then
            echo "User $username already exists. Skipping."
          else
            sudo useradd -m -s /bin/bash "$username"
            echo "User $username created successfully."
          fi

          # copy key
          SSH_DIR = "/home/$username/.ssh"
          if [! -d "$SSH_DIR" ]; then
            sudo -u "$username" mkdir "$SSH_DIR"
            echo "${file("/keys/${username}.pub")}" > "$SSH_DIR/id_ed25519"
            echo "Public key for $username added"
          else
            echo "SSH directory already exists for $username. Skipping"
          fi

          # add user to sudoers file
          if sudo grep -q "$username" /etc/sudoers; then
            echo "User $username is already in sudoers file. Skipping."
          else
            echo "$username ALL=(ALL:ALL) NOPASSWD:ALL" | sudo tee -a /etc/sudoers
            echo "User $username added to sudoers file."
      done < /temp/users.txt
      rm /temp/users.txt 
    EOF

    network_interface {
      network = "bastion"
      access_config {
        nat_ip = "${google_compute_address.bastion_ip.address}"
      }
    }

    service_account {
      email = google_service_account.storage.email
      scopes = ["default"]
    }
}