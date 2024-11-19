#!/bin/bash

# Define variables
user="karim"
host="10.10.1.154"
local_folder="/opt/mt990/file"  # Folder containing files to encrypt
archive_file="/opt/mt990/encrypted_folder.tar"
encrypted_file="${archive_file}.gpg"
remote_dir="/etc/opt/mt990/testing_sftp"
log_file="/opt/mt990/sftp_trial.log"

# Public key for encryption
public_key="/opt/mt990/public_key.asc"

# Temporary list file
tmp_file="/opt/mt990/testingtmpdr.txt"

#####--------------------------- Start script --------------------------------####

# Import public key (only needed once; skip if already imported)
gpg --import $public_key

# Archive the folder (create a .tar file)
echo "Archiving folder: $local_folder" >> $log_file
tar -cf $archive_file -C "$(dirname $local_folder)" "$(basename $local_folder)"
if [ $? -ne 0 ]; then
    echo "Archiving failed at $(date)" >> $log_file
    exit 1
fi

# Encrypt the archive
echo "Encrypting archive: $archive_file" >> $log_file
gpg --yes --batch -r "rifkikarimr@gmail.com" -e "$archive_file"
if [ $? -ne 0 ]; then
    echo "Encryption failed at $(date)" >> $log_file
    exit 1
fi

# Set password for lftp
password_file="/opt/mt990/sftp_s3sapdev.pw"
export LFTP_PASSWORD=$(cat $password_file)

# Transfer the encrypted archive via lftp
echo "Transferring encrypted archive: $encrypted_file" >> $log_file
lftp -d --env-password sftp://$user@$host << EOF
lcd $(dirname $encrypted_file)  # Set local directory
cd $remote_dir  # Change to remote directory
put $(basename $encrypted_file)  # Upload encrypted file
EOF

# Check if the transfer was successful
if [ $? -eq 0 ]; then
    echo "File transfer completed successfully at $(date)" >> $log_file
    # Remove the archive and encrypted file after successful transfer (optional)
    rm -f "$archive_file" "$encrypted_file"
else
    echo "File transfer failed at $(date)" >> $log_file
    exit 1
fi

# Cleanup temporary files
rm -f $tmp_file

echo "Script completed successfully at $(date)" >> $log_file
