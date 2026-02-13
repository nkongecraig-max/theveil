#!/bin/bash
# Sync local project to external drive backup
# Usage: ./sync-backup.sh

LOCAL="/Users/motwe/Documents/NiBiashara/the-veil/"
BACKUP="/Volumes/LaCie/Twe Gaming Industries/the-veil/"

if [ ! -d "$BACKUP" ]; then
    echo "External drive not mounted. Plug in LaCie and try again."
    exit 1
fi

echo "Syncing to backup..."
rsync -av --delete \
    --exclude '.godot/' \
    --exclude 'content/clips/raw/' \
    --exclude '.DS_Store' \
    "$LOCAL" "$BACKUP"

echo "Backup complete: $(date)"
