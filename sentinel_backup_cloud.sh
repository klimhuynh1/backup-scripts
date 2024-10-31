#!/bin/bash

# Source the .env file to set environment variables
source /usr/local/bin/backup-scripts/gotify.env

BACKUP_APPDATA_CHECK=false
BACKUP_TITLE_APPDATA="Restic appdata backup"
LOG_FILE="/usr/local/bin/backup-scripts/backup.log"
PRIORITY=5

# Stop all running Docker containers
docker stop $(docker ps -q)

# Backup to remote repo
restic backup /mnt/docker -r rclone:mymegadrive:sentinel-restic-appdata -v --password-file /usr/local/bin/backup-scripts/sentinel-restic-appdata-password.txt

# Check the exit status of rclone
if [ $? -eq 0 ]; then
    # Append custom text to output.log
    echo "$(date +'%Y-%m-%d %H:%M:%S') - $BACKUP_TITLE_APPDATA was successful." >> "$LOG_FILE"
    BACKUP_APPDATA_CHECK=true
else
    echo "$(date +'%Y-%m-%d %H:%M:%S') - $BACKUP_TITLE_APPDATA was not successful." >> "$LOG_FILE"
fi

if [ "$BACKUP_APPDATA_CHECK" = true ]; then
    TITLE="Senintel Backup Successful"
    MESSAGE="Your data has been successfully backed up."
else
    TITLE="Sentinel Backup Failed"
    MESSAGE="There was an issue with the backup process. Please check the logs for more details."
fi

# Start all Docker containers
docker start $(docker ps -a -q -f "status=exited")

# Send message to gotify
curl -s -S --data '{"message": "'"${MESSAGE}"'", "title": "'"${TITLE}"'", "priority":'"${PRIORITY}"', "extras": {"client::display": {"contentType": "text/markdown"}}}' -H 'Content-Type: application/json' "$URL"

# Check if it's Sunday
if [ "$(date +'%u')" = "7" ]; then
    # Prune restic snapshots
    ./sentinel_backup_housekeeping.sh
fi
