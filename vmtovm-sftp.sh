#!/bin/bash

# Define variables

user="username"
host="host"
local_file="directorylocal"
remote_dir="targetdirectory"
log_file="directorylogs" 

#temporary list file

tmp_file=directorytmp

#####-------------------------------- Start script ----------------------------------------####

find $local_file -maxdepth 1 -type f -mtime +1 -exec ls {} \; >> $tmp_file
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

