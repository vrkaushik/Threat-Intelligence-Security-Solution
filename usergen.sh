#!/bin/bash

# List of user names
USERS=("kaushik" "chris" "haneesha" "april" "yiduo")

# Output file to store public keys
OUTPUT_FILE="public_keys.txt"

# Loop through the list and create users, home directories, and Ed25519 SSH key pairs
for USER in "${USERS[@]}"
do
    # Create user if not already exists
    if id "$USER" &>/dev/null; then
        echo "User $USER already exists. Skipping."
    else
        sudo useradd -m -s /bin/bash "$USER"
        echo "User $USER created successfully."
    fi

    # Create SSH directory and generate Ed25519 key pair
    SSH_DIR="/home/$USER/.ssh"
    if [ ! -d "$SSH_DIR" ]; then
        sudo -u "$USER" mkdir "$SSH_DIR"
        sudo -u "$USER" ssh-keygen -t ed25519 -f "$SSH_DIR/id_ed25519" -N ""
        echo "Ed25519 SSH key pair generated for $USER."
        
        # Append public key to the output file
        cat "$SSH_DIR/id_ed25519.pub" >> "$OUTPUT_FILE"
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

echo "User creation and Ed25519 SSH key generation completed."
