#!/bin/bash

dir_to_monitor="/h2h-asg/dev/BCA/init"
log_file="/opt/h2h-asg/monitor_directory_test.log"

# Ensure the log file exists
touch "$log_file"

# Start Monitoring
echo "$(date): Monitoring started for directory: $dir_to_monitor" >> "$log_file"
inotifywait -m "$dir_to_monitor" -e create -e moved_to --format '%w%f' |
while read new_file; do
  # Log file detection
  echo "$(date): New file detected: $new_file" >> "$log_file"

  # Simulate processing the file (Replace this with your actual processing logic)
  if [[ -f "$new_file" ]]; then
    echo "$(date): Processing file: $new_file" >> "$log_file"
    # Simulate your script call (replace this with the actual script execution)
    /opt/h2h-asg/h2h_trfcat.sh "$new_file" >> "$log_file" 2>&1

    # Log success message
    echo "$(date): SUCCESS: File $new_file processed successfully" >> "$log_file"
  else
    echo "$(date): FAILURE: File $new_file not found or inaccessible" >> "$log_file"
  fi
done
