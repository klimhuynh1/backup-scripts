#!/bin/bash

# Source the .env file to set environment variables
source ./restic.env
source ./gotify.env

BACKUP_APPDATA_CHECK=false
BACKUP_TITLE_APPDATA="Restic appdata backup"
LOG_FILE="/usr/local/bin/backup.log"
PRIORITY=5

# Manually unlock repo
restic -r /mnt/exdisk/restic-appdata --verbose unlock

# Sync local and remote repos
rclone sync --verbose /mnt/exdisk/restic-appdata/ mybackblaze:restic-appdata-mnfll/

# Check the exit status of rclone
if [ $? -eq 0 ]; then
    # Append custom text to output.log
    echo "$(date +'%Y-%m-%d %H:%M:%S') - $BACKUP_TITLE_APPDATA was successful." >> "$LOG_FILE"
    BACKUP_APPDATA_CHECK=true
else
    echo "$(date +'%Y-%m-%d %H:%M:%S') - $BACKUP_TITLE_APPDATA was not successful." >> "$LOG_FILE"
fi


if [ "$BACKUP_APPDATA_CHECK" = true ]; then
    TITLE="Backup Successful"
    MESSAGE="Your data has been successfully backed up."
else
    TITLE="Backup Failed"
    MESSAGE="There was an issue with the backup process. Please check the logs for more details."
fi

curl -s -S --data '{"message": "'"${MESSAGE}"'", "title": "'"${TITLE}"'", "priority":'"${PRIORITY}"', "extras": {"client::display": {"contentType": "text/markdown"}}}' -H 'Content-Type: application/json' "$URL"

# Check if it's Sunday
if [ "$(date +'%u')" = "7" ]; then
    # Prune restic snapshots
    ./backup_housekeeping.sh
fi