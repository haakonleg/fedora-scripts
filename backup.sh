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

KXBAK="$BACKUPDIR/keepassxc"
KXDIR="/home/$USER/.config/keepassxc"

FFBAK="$BACKUPDIR/firefox"
FFDIR="/home/$USER/.mozilla/firefox"

vscode_backup() {
    if [[ -d $VSCODE ]]; then
        echo "Backing up vscode..."

        mkdir -p "$VSBAK"
        # Backup config
        cp "$VSCODE/User/settings.json" "$VSBAK"
        # Backup extensions
        echo "$(code --list-extensions)" > "$VSBAK/extensions"
    fi
}

vscode_restore() {
    if [[ -d "$VSBAK" ]] && [[ $(command -v "code") ]]; then
        echo "Restoring vscode..."

        # Restore config
        cp -f "$VSBAK/settings.json" "$VSCODE/User/"
        # Restore extensions
        while read -r extension; do
            code --install-extension $extension
        done < "$VSBAK/extensions"
    fi
}

gnome_backup() {
    echo "Backing up gnome..."

    mkdir -p "$GNOMEBAK"
    # Backup gnome config
    echo "$(dconf dump /)" > "$GNOMEBAK/gnome"
    # Backup extensions
    cp -r "/home/$USER/.local/share/gnome-shell/extensions" "$GNOMEBAK"
}

ssh_backup() {
    if [[ -d $SSH ]]; then
        echo "Backing up ssh..."

        mkdir -p "$SSHBAK"
        cp $SSH/id_* "$SSHBAK"
    fi
}

ssh_restore() {
    echo "Restoring ssh..."
    if [[ -d "$SSHBAK" ]]; then
        mkdir -p "$SSH"
        cp -rf $SSHBAK/. "$SSH/"
    fi
}

lutris_backup() {
    if [[ -d $LUTRISDIR ]]; then
        echo "Backing up lutris..."

        mkdir -p "$LUTRISBAK/local"
        mkdir -p "$LUTRISBAK/conf"

        cp -r "$LUTRISDIR/pga.db" "$LUTRISDIR/runners" "$LUTRISDIR/banners" "$LUTRISBAK/local"
        cp -r "$LUTRISCONF/system.yml" "$LUTRISCONF/lutris.conf" "$LUTRISCONF/games" "$LUTRISCONF/runners" "$LUTRISBAK/conf"
    fi
}

lutris_restore() {
    if [[ -d "$LUTRISBAK" ]] && [[ $(command -v "lutris") ]]; then
        echo "Restoring lutris..."

        mkdir -p "$LUTRISDIR"
        mkdir -p "$LUTRISCONF"

        cp -rf $LUTRISBAK/local/. "$LUTRISDIR/"
        cp -rf $LUTRISBAK/conf/. "$LUTRISCONF/"
    fi
}

qbittorent_backup() {
    if [[ -d $QBDIR ]]; then
        echo "Backing up qbittorrent..."

        mkdir -p "$QBBAK"
        cp $QBDIR/*.torrent $QBDIR/*.fastresume "$QBCONF/qBittorrent.conf" "$QBCONF/qBittorrent-data.conf" "$QBBAK"
    fi
}

qbittorrent_restore() {
     if [[ -d "$QBBAK" ]] && [[ $(command -v "qbittorrent") ]]; then
        echo "Restoring qbittorrent..."

        mkdir -p "$QBDIR"
        mkdir -p "$QBCONF"

        cp $QBBAK/*.torrent $QBBAK/*.fastresume "$QBDIR"
        cp -f "$QBBAK/qBittorrent.conf" "$QBBAK/qBittorrent-data.conf" "$QBCONF"
     fi
}

keepassxc_backup() {
    if [[ -d $KXDIR ]]; then
        echo "Backing up keepassxc..."

        mkdir -p "$KXBAK"
        cp "$KXDIR/keepassxc.ini" "$KXBAK"
    fi
}

keepassxc_restore() {
    if [[ -d "$KXBAK" ]] && [[ $(command -v "keepassxc") ]]; then
        echo "Restoring keepassxc..."

        mkdir -p "$KXDIR"
        cp -f "$KXBAK/keepassxc.ini" "$KXDIR/"
    fi
}

firefox_backup() {
    local reProfile="Path=([a-z0-9\.]+)"
    if [[ $(cat "$FFDIR/profiles.ini") =~ $reProfile ]]; then
        echo "Backing up firefox..."

        local pDir="${BASH_REMATCH[1]}"

        mkdir -p "$FFBAK"
        cp -a "$FFDIR/$pDir" "$FFBAK/"
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
        keepassxc_backup
        firefox_backup

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
        keepassxc_restore
        ;;
    *)
        echo "Usage: $0 {backup|restore}"
        exit 1
esac
