#!/bin/bash

# Define directory to watch
WATCH_DIR="/home/karim/secretfile"
# Define the remote server and destination directory
REMOTE_SERVER="karim@10.10.1.154"
REMOTE_DIR="/home/karim"
# Define the recipient's email for encryption
RECIPIENT_EMAIL="wendy@cagur.mail"
# Define the key size and type (RSA 4096 is recommended)
KEY_SIZE=4096

# Function to generate a new GPG key pair (if needed)
generate_gpg_key() {
  # Check if the key already exists
  if ! gpg --list-keys "$RECIPIENT_EMAIL" &>/dev/null; then
    echo "Generating new GPG key pair..."
    
    # Generate a new key pair (use RSA, 4096 bits)
    gpg --batch --gen-key << EOF
    Key-Type: RSA
    Key-Length: $KEY_SIZE
    Name-Real: Your Name
    Name-Email: $RECIPIENT_EMAIL
    Expire-Date: 0
    %no-protection
EOF
    
    echo "Key pair generated for $RECIPIENT_EMAIL"
  else
    echo "GPG key already exists for $RECIPIENT_EMAIL"
  fi
}

# Function to encrypt files with the recipient's public key
encrypt_file() {
  local file=$1
  # Encrypt the file using the recipient's public key
  gpg --output "$file.gpg" --encrypt --recipient "$RECIPIENT_EMAIL" "$file"
  
  # Check if encryption was successful
  if [ $? -eq 0 ]; then
    echo "File encrypted: $file"
  else
    echo "Encryption failed for: $file"
  fi
}

# function to send files via LFTP
send_files() {
  local file=$1
  # Use LFTP to send encrypted file
  lftp -u username,password -e "put $file; bye" sftp://$REMOTE_SERVER/$REMOTE_DIR
  # Check if LFTP transfer was successful
  if [ $? -eq 0 ]; then
    echo "File successfully sent to $REMOTE_SERVER"
  else
    echo "Failed to send file"
  fi
}

# Generate the GPG key pair if needed
generate_gpg_key

# Monitor the directory for new files
inotifywait -m -e close_write "$WATCH_DIR" | while read dir event file; do
  # Only process regular files
  if [ -f "$dir$file" ]; then
    echo "New file detected: $file"
    
    # Encrypt the file using the recipient's public key
    encrypt_file "$dir$file"
    
    # Send the encrypted file
    send_files "$dir$file.gpg"
    
    # Optionally, remove the original and encrypted files after sending
    rm "$dir$file" "$dir$file.gpg"
  fi
done
