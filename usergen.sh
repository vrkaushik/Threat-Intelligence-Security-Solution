#!/bin/bash
    OUTPUT_FILE="public_keys.txt"
    cat ${var.users_file} | while IFS= read -r line
    do
      USER=$(echo $line | cut -d ' ' -f 1)
      PUBLIC_KEY=$(echo $line | cut -d ' ' -f 2)
      
      # Add commands to configure user accounts based on the input file
      # Create user if not already exists
        if id "$USER" &>/dev/null; then
            echo "User $USER already exists. Skipping."
        else
            sudo useradd -m -s /bin/bash "$USER"
            echo "User $USER created successfully."
        fi

    # Create SSH directory
        SSH_DIR="/home/$USER/.ssh"
        if [ ! -d "$SSH_DIR" ]; then
            sudo -u "$USER" mkdir "$SSH_DIR"
            # Append public key to the output file
            echo "$PUBLIC_KEY" >> "$OUTPUT_FILE"
            echo "Public key for $USER added to $OUTPUT_FILE."
        else
            echo "SSH directory already exists for $USER. Skipping key pair generation."
        fi


    # Add user to sudoers file
        if sudo grep -q "$USER" /etc/sudoers; then
            echo "User $USER is already in sudoers file. Skipping."
        else
            echo "$USER ALL=(ALL:ALL) NOPASSWD:ALL" | sudo tee -a /etc/sudoers
            echo "User $USER added to sudoers file."
        fi
    done
    echo "User creation script execution completed"