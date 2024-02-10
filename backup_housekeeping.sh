#!/bin/bash

# Source the .env file to set the environment variables
source ./restic.env
source ./gotify.env

CLEANUP_APPDATA_CHECK=false
LOG_FILE="/usr/local/bin/cleanup.log"
PRIORITY=5

# Manually unlock repo
restic -r /mnt/exdisk/restic-appdata --verbose unlock

# Removing snapshots according to a policy
restic -r /mnt/exdisk/restic-appdata --verbose forget --keep-last 1 --keep-daily 7 --keep-weekly 4 --keep-monthly 6 --prune

# Check the exit status
if [ $? -eq 0 ]; then
    # Append custom text to output.log
    echo "$(date +'%Y-%m-%d %H:%M:%S') - Restic appdata forget and prune were successful." >> "$LOG_FILE"
    CLEANUP_APPDATA_CHECK=true
else
    echo "$(date +'%Y-%m-%d %H:%M:%S') - Restic appdata forget and prune were not successful." >> "$LOG_FILE"

fi

if [ "$CLEANUP_APPDATA_CHECK" = true ]; then
    TITLE="Restic Clean Up Successful"
    MESSAGE="The clean up process for Restic snapshots completed successfully."
else
    TITLE="Restic Clean Up Failed"
    MESSAGE="There was an issue with the Restic cleanup process. Please check the logs for more details."
fi

curl -s -S --data '{"message": "'"${MESSAGE}"'", "title": "'"${TITLE}"'", "priority":'"${PRIORITY}"', "extras": {"client::display": {"contentType": "text/markdown"}}}' -H 'Content-Type: application/json' "$URL"