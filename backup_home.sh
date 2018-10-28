#!/bin/bash

if [[ $UID == 0 ]]; then
    echo "Do not run as root"
    exit 1
fi

if [[ $1 == "--schedule" ]]; then
    SCRIPTPATH=$(realpath $0)
    SDDIR="/home/$USER/.config/systemd/user"
    mkdir -p $SDDIR

    echo "Destination to place backup file:"
    read DEST

    if [[ ! -d $DEST ]]; then
        echo "Error: not a directory"
        exit 1
    fi

    # Create systemd service to set at boot
    UNITSERVICE="$SDDIR/backup-home.service"
    declare -a SERVICE_CONTENTS=(
        '[Unit]'
        'Description=Backup home directory'
        ''
        '[Service]'
        "Environment=DEST=$DEST USER=$USER"
        "ExecStart=$SCRIPTPATH"
        ''
        '[Install]'
        'WantedBy=default.target'
    )

    UNITTIMER="$SDDIR/backup-home.timer"
    declare -a TIMER_CONTENTS=(
        '[Unit]'
        'Description=Schedule backup home dir'
        ''
        '[Timer]'
        'OnCalendar=daily'
        "Unit=backup-home.service"
        ''
        '[Install]'
        'WantedBy=default.target'
    )

    printf "%s\n" "${SERVICE_CONTENTS[@]}" > $UNITSERVICE
    printf "%s\n" "${TIMER_CONTENTS[@]}" > $UNITTIMER

    systemctl --user daemon-reload
    systemctl --user enable backup-home.timer --now

    exit 0
fi

TIME=$(date +"%m%d%y")

# Delete old backups, keep the last 5 days
find $DEST -maxdepth 1 -type f -name "linux_backup_*.tar.gz" | sort -n | head -n -5 | while read -r oldfile; do
    echo "Deleting old backup $oldfile"
    rm -rf $oldfile
done

echo "Starting backup of home directory..."
tar cpzfP "$DEST/linux_backup_$TIME.tar.gz" "/home/$USER/"
