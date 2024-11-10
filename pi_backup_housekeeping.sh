#!/bin/bash

# Source the .env file to set the environment variables
source /usr/local/bin/backup-scripts/gotify.env

CLEANUP_APPDATA_CHECK=false
CLEANUP_DASHCAM_CHECK=false
PRUNE_TITLE_APPDATA="Restic appdata prune"
PRUNE_TITLE_DASHCAM="Restic dashcam prune"
LOG_FILE="/usr/local/bin/backup-scripts/housekeeping.log"
PRIORITY=5

# Removing snapshots according to a policy
restic -r /mnt/exdisk/nucleus-restic-appdata --verbose --password-file /usr/local/bin/backup-scripts/nucleus-restic-appdata-password.txt forget --keep-last 1 --keep-daily 5 --keep-weekly 2 --keep-monthly 3 --prune

# Check the exit status
if [ $? -eq 0 ]; then
    # Append custom text to output.log
    echo "$(date +'%Y-%m-%d %H:%M:%S') - $PRUNE_TITLE_APPDATA was successful." >> "$LOG_FILE"
    CLEANUP_APPDATA_CHECK=true
else
    echo "$(date +'%Y-%m-%d %H:%M:%S') - $PRUNE_TITLE_APPDATA was not successful." >> "$LOG_FILE"

fi

# Removing snapshots according to a policy
restic -r /mnt/exdisk/nucleus-restic-dashcam --verbose --password-file /usr/local/bin/backup-scripts/nucleus-restic-dashcam.txt forget --keep-last 1 --keep-daily 5 --keep-weekly 2 --keep-monthly 3 --prune

# Check the exit status
if [ $? -eq 0 ]; then
    # Append custom text to output.log
    echo "$(date +'%Y-%m-%d %H:%M:%S') - $PRUNE_TITLE_DASHCAM was successful." >> "$LOG_FILE"
    CLEANUP_DASHCAM_CHECK=true
else
    echo "$(date +'%Y-%m-%d %H:%M:%S') - $PRUNE_TITLE_DASHCAM was not successful." >> "$LOG_FILE"

fi

# Removing snapshots according to a policy
restic -r /mnt/exdisk/nucleus-restic-temp --verbose --password-file /usr/local/bin/backup-scripts/nucleus-restic-temp.txt forget --keep-last 1 --keep-daily 5 --keep-weekly 2 --keep-monthly 3 --prune

# Check the exit status
if [ $? -eq 0 ]; then
    # Append custom text to output.log
    echo "$(date +'%Y-%m-%d %H:%M:%S') - $PRUNE_TITLE_DASHCAM was successful." >> "$LOG_FILE"
    CLEANUP_TEMP_CHECK=true
else
    echo "$(date +'%Y-%m-%d %H:%M:%S') - $PRUNE_TITLE_DASHCAM was not successful." >> "$LOG_FILE"

fi

if [ "$CLEANUP_APPDATA_CHECK" = true ] && [ "$CLEANUP_DASHCAM_CHECK" = true ] && [ "$CLEANUP_TEMP_CHECK" = true ]; then
    TITLE="Nucleus Housekeeping Successful"
    MESSAGE="The housekeeping process was completed successfully."
else
    TITLE="Nucleus Housekeeping Failed"
    MESSAGE="There was an issue with the housekeeping process. Please check the logs for more details."
fi

curl -s -S --data '{"message": "'"${MESSAGE}"'", "title": "'"${TITLE}"'", "priority":'"${PRIORITY}"', "extras": {"client::display": {"contentType": "text/markdown"}}}' -H 'Content-Type: application/json' "$URL"
