#!/bin/bash

if [[ $UID == 0 ]]; then
    echo "Do not run as root"
    exit 1
fi

# Global vars
BACKUPDIR='backup'

VSBAK="$BACKUPDIR/vscode"
VSCODE="/home/$USER/.config/Code"

GNOMEBAK="$BACKUPDIR/gnome"

SSHBAK="$BACKUPDIR/ssh"
SSH="/home/$USER/.ssh"

LUTRISBAK="$BACKUPDIR/lutris"
LUTRISDIR="/home/$USER/.local/share/lutris"
LUTRISCONF="/home/$USER/.config/lutris"

QBBAK="$BACKUPDIR/qbittorrent"
QBDIR="/home/$USER/.local/share/data/qBittorrent/BT_backup"
QBCONF="/home/$USER/.config/qBittorrent"

vscode_backup() {
    if [[ -d $VSCODE ]]; then
        mkdir -p "$VSBAK"
        # Backup config
        cp "$VSCODE/User/settings.json" "$VSBAK"
        # Backup extensions
        echo "$(code --list-extensions)" > "$VSBAK/extensions"
    fi
}

vscode_restore() {
    if [[ $(command -v "code") ]]; then
        # Restore config
        cp -f "$VSBAK/settings.json" "$VSCODE/User/"
        # Restore extensions
        while read -r extension; do
            code --install-extension $extension
        done < "$VSBAK/extensions"
    fi
}

gnome_backup() {
    mkdir -p "$GNOMEBAK"
    # Backup gnome config
    echo "$(dconf dump /)" > "$GNOMEBAK/gnome"
    # Backup extensions
    cp -r "/home/$USER/.local/share/gnome-shell/extensions" "$GNOMEBAK"
}

ssh_backup() {
    if [[ -d $SSH ]]; then
        mkdir -p "$SSHBAK"
        cp $SSH/id_* "$SSHBAK"
    fi
}

ssh_restore() {
    mkdir -p "$SSH"
    cp -rf $SSHBAK. "$SSH"
}

lutris_backup() {
    if [[ -d $LUTRISDIR ]]; then
        mkdir -p "$LUTRISBAK/local"
        mkdir -p "$LUTRISBAK/conf"

        cp -r "$LUTRISDIR/pga.db" "$LUTRISDIR/runners" "$LUTRISDIR/banners" "$LUTRISBAK/local"
        cp -r "$LUTRISCONF/system.yml" "$LUTRISCONF/lutris.conf" "$LUTRISCONF/games" "$LUTRISCONF/runners" "$LUTRISBAK/conf"
    fi
}

lutris_restore() {
    if [[ $(command -v "lutris") ]]; then
        mkdir -p "$LUTRISDIR"
        mkdir -p "$LUTRISCONF"

        cp -rf $LUTRISBAK/local/. "$LUTRISDIR"
        cp -rf $LUTRISBAK/conf/. "$LUTRISCONF"
    fi
}

qbittorent_backup() {
    if [[ -d $QBDIR ]]; then
        mkdir -p "$QBBAK"
        cp $QBDIR/*.torrent $QBDIR/*.fastresume "$QBCONF/qBittorrent.conf" "$QBCONF/qBittorrent-data.conf" "$QBBAK"
    fi
}

qbittorrent_restore() {
     if [[ $(command -v "qbittorrent") ]]; then
        mkdir -p "$QBDIR"
        mkdir -p "$QBCONF"

        cp $QBBAK/*.torrent $QBBAK/*.fastresume "$QBDIR"
        cp -f "$QBBAK/qBittorrent.conf" "$QBBAK/qBittorrent-data.conf" "$QBCONF"
     fi
}

case "$1" in
    "backup")
        rm -rf "$BACKUPDIR"

        vscode_backup
        gnome_backup
        ssh_backup
        lutris_backup
        qbittorent_backup

        echo "Compressing..."
        tar zcf "$BACKUPDIR.tar.gz" "$BACKUPDIR"
        rm -rf "$BACKUPDIR"
        ;;
    "restore")
        if [[ ! -f "$BACKUPDIR.tar.gz" ]]; then
            echo "Error: no $BACKUPDIR.tar.gz found"
            exit 1
        fi

        echo "Uncompressing..."
        tar zxf "$BACKUPDIR.tar.gz"

        vscode_restore
        ssh_restore
        lutris_restore
        qbittorrent_restore

        rm -rf "$BACKUPDIR"
        ;;
    *)
        echo "Usage: $0 {backup|restore}"
        exit 1
esac
