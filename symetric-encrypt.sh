#!/bin/bash

# Define directory to watch
WATCH_DIR="/path/to/watch/directory"
# Define the remote server and destination directory
REMOTE_SERVER="user@remote-vm"
REMOTE_DIR="/path/to/remote/directory"
# Define the passphrase (single key for all files)
PASSPHRASE="your-shared-passphrase-here"

# Function to encrypt files with OpenPGP using symmetric encryption
encrypt_file() {
  local file=$1
  # Encrypt the file using symmetric encryption with a passphrase
  gpg --output "$file.gpg" --symmetric --cipher-algo AES256 --passphrase "$PASSPHRASE" "$file"
  
  # Check if encryption was successful
  if [ $? -eq 0 ]; then
    echo "File encrypted: $file"
  else
    echo "Encryption failed for: $file"
  fi
}

# Function to send files via LFTP
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

# Monitor the directory for new files
inotifywait -m -e close_write "$WATCH_DIR" | while read dir event file; do
  # Only process regular files
  if [ -f "$dir$file" ]; then
    echo "New file detected: $file"
    
    # Encrypt the file using symmetric encryption
    encrypt_file "$dir$file"
    
    # Send the encrypted file
    send_files "$dir$file.gpg"
    
    # Optionally, remove the original and encrypted files after sending
    rm "$dir$file" "$dir$file.gpg"
  fi
done
