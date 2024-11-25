 #!/bin/bash
    READY_TO_ENCRYPT="/h2h-asg/dev/BCA/init/"
    READY_TO_SEND="/h2h-asg/dev/BCA/encrypted/"
    ARCHIVE_FOLDER="/h2h-asg/dev/BCA/archived"
    FAILED_FOLDER="/h2h-asg/dev/BCA/failed"
    LFTP_DEST="sftp://username@ip-address/remote_folder"
    PUB_KEY_PATH="/opt/h2h-asg/key/sftp_encsap_pub_test.key"

    password_file="/opt/h2h-asg/pwd/sftp_encsap.pw"  
    export LFTP_PASSWORD=$(cat $password_file)

    # Ensure all folders exist
    # mkdir -p "$READY_TO_ENCRYPT" "$READY_TO_SEND" "$ARCHIVE_FOLDER" "$FAILED_FOLDER"

    # Encrypt files in "Ready to Encrypt" folder
    for file in "$READY_TO_ENCRYPT"/*; do
        if [[ -f $file ]]; then
            output_file="$READY_TO_SEND/$(basename "$file").gpg"
            gpg --output "$output_file" --encrypt --recipient "BCA" "$file"
            if [[ $? -eq 0 ]]; then
                echo "Encrypted: $file" >> /opt/h2h-asg/monitor_directory_test.log
                rm "$file"  # Remove original file after encyrption
                echo "Original file has been removed" >> /opt/h2h-asg/monitor_directory_test.log
            else
                echo "Failed to encrypt: $file" >> /opt/h2h-asg/monitor_directory_test.log
                mv "$file" "$FAILED_FOLDER/"   # Move to Failed folder on encryption error
            fi
        fi
    done

    # Move encrypted files to "Ready to Send" folder
    for encrypted_file in "$READY_TO_SEND"/*.gpg; do
        if [[ -f $encrypted_file ]]; then
            mv "$encrypted_file" "$READY_TO_SEND/"
            echo "Moved encrypted file to 'Ready to Send': $encrypted_file" >> /opt/h2h-asg/monitor_directory_test.log
        fi
    done

    # Check if there are encrypted files to transfer
    if [[ ! $(ls -A "$READY_TO_SEND") ]]; then
        echo "No files to send. Exiting." >> /opt/h2h-asg/monitor_directory_test.log
        exit 0
    fi

    Transfer encrypted files in "Ready to Send" folder
    transfer_successful=true
    for file in "$READY_TO_SEND"/*; do
        if [[ -f $file ]]; then
            lftp -e -d --env-password "put $file; bye" $LFTP_DEST
            if [[ $? -eq 0 ]]; then
                echo "Transferred: $file"
                mv "$file" "$ARCHIVE_FOLDER/"  # Move encrupted file to Archive folder after successful transfer
            else
                echo "Failed to transfer: $file" >> /opt/h2h-asg/monitor_directory.log
                transfer_successful=false
            fi
        fi
    done

    Transfer the public key file
    lftp -e "put $PUB_KEY_PATH; bye" $LFTP_DEST
    if [[ $? -eq 0 ]]; then
        echo "Public key transferred successfully." >> /opt/h2h-asg/monitor_directory.log
    else
        echo "Failed to transfer public key." >> /opt/h2h-asg/monitor_directory.log
        transfer_successful=false
    fi

    Final status
    if [ "$transfer_successful" = true ]; then
        echo "All files processed and transferred successfully." >> /opt/h2h-asg/monitor_directory_test.log
    else
        echo "Some files failed during the transfer process." >> /opt/h2h-asg/monitor_directory_test.log
        exit 1
    fi