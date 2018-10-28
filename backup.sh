#!/bin/bash

if [[ $UID == 0 ]]; then
    echo "Do not run as root"
    exit 1
fi

# Global vars
BACKUPDIR='backup'

vscode_backup() {
    mkdir -p $BACKUPDIR/vscode

    # Backup config
    cp "/home/$USER/.config/Code/User/settings.json" "$BACKUPDIR/vscode"

    # Backup extensions
    echo "$(code --list-extensions)" > "$BACKUPDIR/vscode/extensions"
}

vscode_restore() {
    # Restore config
    cp -f "$BACKUPDIR/vscode" "/home/$USER/.config/Code/User/settings.json"

    # Restore extensions
    while read -r extension; do
        code --install-extension $extension
    done < "$BACKUPDIR/vscode/extensions"
}

gnome_backup() {
    mkdir -p $BACKUPDIR/gnome

    # Backup gnome config
    echo "$(dconf dump /)" > "$BACKUPDIR/gnome/gnome"

    # Backup extensions
    cp -r "/home/$USER/.local/share/gnome-shell/extensions" "$BACKUPDIR/gnome/"
}

case "$1" in
    "backup")
        vscode_backup
        gnome_backup
        ;;
    "restore")
        vscode_restore
        ;;
    *)
        echo "Usage: $0 {backup|restore}"
        exit 1
esac
