#!/bin/bash

# TODO: Fix hardcoded directories

# Source the .env file to set environment variables
source /usr/local/bin/backup-scripts/gotify.env

BACKUP_APPDATA_CHECK=false
BACKUP_DASHCAM_CHECK=false
BACKUP_TITLE_APPDATA="Restic appdata backup"
BACKUP_TITLE_DASHCAM="Restic dashcam backup"
LOG_FILE="/usr/local/bin/backup-scripts/backup.log"
PRIORITY=5

# Manually unlock repo
restic -r /mnt/exdisk/nucleus-restic-appdata --verbose --password-file /usr/local/bin/backup-scripts/nucleus-restic-appdata-password.txt unlock

# Sync local and remote repos
rclone sync --verbose /mnt/exdisk/nucleus-restic-appdata/ mymegadrive:nucleus-restic-appdata

# Check the exit status of rclone
if [ $? -eq 0 ]; then
    # Append custom text to output.log
    echo "$(date +'%Y-%m-%d %H:%M:%S') - $BACKUP_TITLE_APPDATA was successful." >> "$LOG_FILE"
    BACKUP_APPDATA_CHECK=true
else
    echo "$(date +'%Y-%m-%d %H:%M:%S') - $BACKUP_TITLE_APPDATA was not successful." >> "$LOG_FILE"
fi

# Manually unlock repo
restic -r /mnt/exdisk/nucleus-restic-dashcam --verbose --password-file /usr/local/bin/backup-scripts/nucleus-restic-dashcam.txt unlock

# Sync local and remote repos
rclone sync --verbose /mnt/exdisk/nucleus-restic-dashcam/ mymegadrive:nucleus-restic-dashcam

# Check the exit status of rclone
if [ $? -eq 0 ]; then
    # Append custom text to output.log
    echo "$(date +'%Y-%m-%d %H:%M:%S') - $BACKUP_TITLE_DASHCAM was successful." >> "$LOG_FILE"
    BACKUP_DASHCAM_CHECK=true
else
    echo "$(date +'%Y-%m-%d %H:%M:%S') - $BACKUP_TITLE_DASHCAM was not successful." >> "$LOG_FILE"
fi

if [ "$BACKUP_APPDATA_CHECK" = true ] && [ "$BACKUP_DASHCAM_CHECK" = true ]; then
    TITLE="Nucleus Backup Successful"
    MESSAGE="Your data has been successfully backed up."
else
    TITLE="Nucleus Backup Failed"
    MESSAGE="There was an issue with the backup process. Please check the logs for more details."
fi

curl -s -S --data '{"message": "'"${MESSAGE}"'", "title": "'"${TITLE}"'", "priority":'"${PRIORITY}"', "extras": {"client::display": {"contentType": "text/markdown"}}}' -H 'Content-Type: application/json' "$URL"

# Check if it's Sunday
if [ "$(date +'%u')" = "7" ]; then
    # Prune restic snapshots
    /usr/local/bin/backup-scripts/pi_backup_housekeeping.sh
fi
