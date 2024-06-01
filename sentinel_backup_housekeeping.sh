#!/bin/bash

# Source the .env file to set the environment variables
source /usr/local/bin/backup-scripts/restic.env
source /usr/local/bin/backup-scripts/gotify.env

CLEANUP_APPDATA_CHECK=false
LOG_FILE="/usr/local/bin/backup-scripts/housekeeping.log"
PRIORITY=5

# Manually unlock repo
restic -r /mnt/backups/sentinel-restic-appdata --verbose unlock

# Removing snapshots according to a policy
restic -r /mnt/backups/sentinel-restic-appdata --verbose forget --keep-last 1 --keep-daily 7 --keep-weekly 4 --prune

# Check the exit status
if [ $? -eq 0 ]; then
    # Append custom text to output.log
    echo "$(date +'%Y-%m-%d %H:%M:%S') - Restic appdata forget and prune were successful." >> "$LOG_FILE"
    CLEANUP_APPDATA_CHECK=true
else
    echo "$(date +'%Y-%m-%d %H:%M:%S') - Restic appdata forget and prune were not successful." >> "$LOG_FILE"

fi

if [ "$CLEANUP_APPDATA_CHECK" = true ]; then
    TITLE="Sentinel Housekeeping Successful"
    MESSAGE="The housekeeping process was completed successfully."
else
    TITLE="Sentinel Housekeeping Failed"
    MESSAGE="There was an issue with the housekeeping process. Please check the logs for more details."
fi

curl -s -S --data '{"message": "'"${MESSAGE}"'", "title": "'"${TITLE}"'", "priority":'"${PRIORITY}"', "extras": {"client::display": {"contentType": "text/markdown"}}}' -H 'Content-Type: application/json' "$URL"
