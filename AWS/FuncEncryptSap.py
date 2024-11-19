import boto3

def lambda_handler(event, context):
    # AWS SSM and EC2 setup
    ssm_client = boto3.client('ssm')
    instance_id = "i-002f74db8ff28b74f"  

    # Embedded Bash script
    bash_script = """
    #!/bin/bash
    READY_TO_ENCRYPT="/h2h-asg/dev/BCA/init/"
    READY_TO_SEND="/h2h-asg/dev/BCA/encrypted/"
    ARCHIVE_FOLDER="/h2h-asg/dev/BCA/archive"
    FAILED_FOLDER="/h2h-asg/dev/BCA/failed"
    LFTP_DEST="sftp://username@ip-address/remote_folder"
    PUB_KEY_PATH="/opt/h2h-asg/sftp_encsap.pub"

    password_file="/opt/h2h-asg/sftp_encsap.pw"  
    export LFTP_PASSWORD=$(cat $password_file)

    # Ensure all folders exist
    mkdir -p "$READY_TO_ENCRYPT" "$READY_TO_SEND" "$ARCHIVE_FOLDER" "$FAILED_FOLDER"

    # Encrypt files in "Ready to Encrypt" folder
    for file in "$READY_TO_ENCRYPT"/*; do
        if [[ -f $file ]]; then
            output_file="$READY_TO_SEND/$(basename "$file").gpg"
            gpg --output "$output_file" --encrypt --recipient "BCA" "$file"
            if [[ $? -eq 0 ]]; then
                echo "Encrypted: $file"
                mv "$file" "$ARCHIVE_FOLDER/"  # Move original file to Archive after encryption
            else
                echo "Failed to encrypt: $file"
                mv "$file" "$FAILED_FOLDER/"   # Move to Failed folder on encryption error
            fi
        fi
    done

    # Check if there are encrypted files to transfer
    if [[ ! $(ls -A "$READY_TO_SEND") ]]; then
        echo "No files to send. Exiting."
        exit 0
    fi

    # Transfer encrypted files in "Ready to Send" folder
    transfer_successful=true
    for file in "$READY_TO_SEND"/*; do
        if [[ -f $file ]]; then
            lftp -e -d --env-password "put $file; bye" $LFTP_DEST
            if [[ $? -eq 0 ]]; then
                echo "Transferred: $file"
                rm -f "$file"  # Remove encrypted file after successful transfer
            else
                echo "Failed to transfer: $file"
                transfer_successful=false
            fi
        fi
    done

    # Transfer the public key file
    lftp -e "put $PUB_KEY_PATH; bye" $LFTP_DEST
    if [[ $? -eq 0 ]]; then
        echo "Public key transferred successfully."
    else
        echo "Failed to transfer public key."
        transfer_successful=false
    fi

    # Final status
    if [ "$transfer_successful" = true ]; then
        echo "All files processed and transferred successfully."
    else
        echo "Some files failed during the transfer process."
        exit 1
    fi
    """

    try:
        # Execute the script on the EC2 instance using SSM
        response = ssm_client.send_command(
            InstanceIds=[instance_id],
            DocumentName="AWS-RunShellScript",
            Parameters={"commands": [bash_script]},
        )

        command_id = response['Command']['CommandId']
        print(f"Command sent successfully. Command ID: {command_id}")

        # Wait for the command to complete and fetch the output
        output = ssm_client.get_command_invocation(
            CommandId=command_id,
            InstanceId=instance_id,
        )
        print(f"Command output: {output['StandardOutputContent']}")

    except Exception as e:
        print(f"Failed to execute command: {e}")
        raise

    return {"statusCode": 200, "body": "Bash script executed on EC2"}
