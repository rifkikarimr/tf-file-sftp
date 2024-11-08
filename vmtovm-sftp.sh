#!/bin/bash

# Define variables

user="karim"
host="10.10.1.154"
local_file="/opt/mt990/file/dummytext.txt"
remote_dir="/etc/opt/mt990/testing_sftp"
log_file="/opt/mt990/sftp_trial.log" 

#temporary list file

tmp_file=/opt/mt990/testingtmpdr.txt

#####-------------------------------- Start script ----------------------------------------####

find $local_file >> $tmp_file
echo Start Transfer >> $log_file

while read file ; do

# Set password

password_file="/opt/mt990/sftp_s3sapdev.pw"  
export LFTP_PASSWORD=$(cat $password_file)

# LFTP command to transfer file

cd /opt/mt990/file || exit 1
lftp -d --env-password sftp://$user@$host << EOF
lcd $(dirname $local_file)  # Set local directory
cd $remote_dir  # Change to remote directory
mput $(basename $local_file)
EOF

done < $tmp_file

# Check if the transfer was successful

if [ $? -eq 0 ]; then
    echo "File transfer completed successfully at $(date)" >> $log_file
else
    echo "File transfer failed at $(date)" >> $log_file

fi

