#!/bin/bash

# Define the directory to watch and the log file
WATCHED_DIR="/h2h-asg/dev/BCA/init"
LOG_FILE="/opt/h2h-asg/monitor_directory_test.log

# Define the local .sh script to test
LOCAL_SCRIPT="/opt/h2h-asg/encrypt_move_transfer_test.sh"

# Watch the directory for new files
inotifywait -m "$WATCHED_DIR" -e create |
    while read path action file; do
        echo "$(date): $action $file in $path" >> "$LOG_FILE"

        # Execute the local test script with file details
        echo "Triggering local script with file: $file"
        bash "$LOCAL_SCRIPT" "$path/$file"

        # Log the execution
        echo "$(date): Local script executed for $file" >> "$LOG_FILE"
    done
