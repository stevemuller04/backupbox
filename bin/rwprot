#!/bin/bash

# Ransomware protection: create backups of a backup in a safe location

if [[ $# -lt 2 ]]; then
	echo 'Usage:' >> /dev/stderr
	echo "  $0 <live location of backup> <ransom protection folder>" >> /dev/stderr
	exit 1
fi

BACKUP_SOURCE=$1
BACKUP_TARGET=$2
LOG=$(basename "$0")
TODAY=$(date +%Y-%m-%d)

# First copy the daily backup
/usr/local/bin/dirbak --name "$TODAY" "$BACKUP_SOURCE" "$BACKUP_TARGET/daily" > >(systemd-cat -p "info" -t "$LOG") 2>&1
result=$?
if [[ $result -ne 0 ]]; then
	echo "Backup failed: dirbak exited with code $result" | systemd-cat -p "crit" -t "$LOG"
	exit 1
fi

# Then rotate weekly/monthly/yearly copies
/usr/local/bin/rot -o "$BACKUP_TARGET" --no-create-daily --suffix '' "$BACKUP_TARGET/daily/$TODAY" > >(systemd-cat -p "info" -t "$LOG") 2>&1
result=$?
if [[ $result -ne 0 ]]; then
	echo "Backup failed: rot exited with code $result" | systemd-cat -p "crit" -t "$LOG"
	exit 1
fi

exit 0
