#!/bin/bash

# Source the .env file to set environment variables
source /usr/local/bin/backup-scripts/restic.env
source /usr/local/bin/backup-scripts/gotify.env

BACKUP_APPDATA_CHECK=false
BACKUP_DASHCAM_CHECK=false
BACKUP_TITLE_APPDATA="Restic appdata backup"
BACKUP_TITLE_DASHCAM="Restic dashcam backup"
LOG_FILE="/usr/local/bin/backup-scripts/backup.log"
PRIORITY=5

# Manually unlock repo
restic -r /mnt/exdisk/restic-appdata --verbose unlock

# Sync local and remote repos
rclone sync --verbose /mnt/exdisk/restic-appdata/ mymegadrive:restic-appdata-mnfll

# Check the exit status of rclone
if [ $? -eq 0 ]; then
    # Append custom text to output.log
    echo "$(date +'%Y-%m-%d %H:%M:%S') - $BACKUP_TITLE_APPDATA was successful." >> "$LOG_FILE"
    BACKUP_APPDATA_CHECK=true
else
    echo "$(date +'%Y-%m-%d %H:%M:%S') - $BACKUP_TITLE_APPDATA was not successful." >> "$LOG_FILE"
fi

# Manually unlock repo
restic -r /mnt/exdisk/restic-dashcam --verbose unlock

# Sync local and remote repos
rclone sync --verbose /mnt/exdisk/restic-dashcam/ mymegadrive:restic-dashcam-mnfll

# Check the exit status of rclone
if [ $? -eq 0 ]; then
    # Append custom text to output.log
    echo "$(date +'%Y-%m-%d %H:%M:%S') - $BACKUP_TITLE_DASHCAM was successful." >> "$LOG_FILE"
    BACKUP_DASHCAM_CHECK=true
else
    echo "$(date +'%Y-%m-%d %H:%M:%S') - $BACKUP_TITLE_DASHCAM was not successful." >> "$LOG_FILE"
fi

if [ "$BACKUP_APPDATA_CHECK" = true ] && [ "$BACKUP_DASHCAM_CHECK" = true ]; then
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
    ./pi_backup_housekeeping.sh
fi
