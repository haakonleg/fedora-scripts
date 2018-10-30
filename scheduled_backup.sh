#!/bin/bash

if [[ $UID != 0 ]]; then
    echo "Script must be run as root"
    exit 1
fi

SCRIPT="backup.sh"
SD_DIR="/etc/systemd/system"
UNIT_SERVICE="backup.service"
UNIT_TIMER="backup.timer"

echo "Destination to place backup file:"
read DEST

if [[ ! -d $DEST ]]; then
    echo "Error: not a directory"
    exit 1
fi

echo '#!/bin/bash
# Delete old backups, keep the last 5 days
find $DEST -maxdepth 1 -type f -name "linux_backup_*.tar.gz" | sort -n | head -n -5 | while read -r oldfile; do
    echo "Deleting old backup $oldfile"
    rm -rf $oldfile
done

HOMEDIR="/home/$USER"
TIME=$(date +"%m%d%y")

tar cpzfP "$DEST/linux_backup_$TIME.tar.gz" \
    --exclude="$HOMEDIR/.cache" \
    --exclude="$HOMEDIR/.var" \
    --exclude="$HOMEDIR/snap" \
    --exclude="$HOMEDIR/Android" \
    "$HOMEDIR/" \
    "/etc/"

chown $USER:$USER "$DEST/linux_backup_$TIME.tar.gz"' > "/$SCRIPT"
chmod +x "/$SCRIPT"

# Create systemd service
echo '[Unit]
Description=Backup directories

[Service]
Environment='"DEST=$DEST USER=$USER"'
ExecStart=/backup.sh

[Install]
WantedBy=default.target' > "$SD_DIR/$UNIT_SERVICE"

# Create systemd timer
echo '[Unit]
Description=Schedule backup

[Timer]
OnCalendar=daily
Persistent=true
Unit='$UNIT_SERVICE'

[Install]
WantedBy=default.target' > "$SD_DIR/$UNIT_TIMER"

systemctl daemon-reload
systemctl enable $UNIT_TIMER --now
