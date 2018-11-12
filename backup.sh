#!/bin/bash

if [[ $UID == 0 ]]; then
    echo "Do not run as root"
    exit 1
fi

# Global vars
BACKUPDIR='backup'

vscode() {
    local backupDir="$BACKUPDIR/vscode"
    local vscode="/home/$USER/.config/Code"

    if [[ $1 -eq "backup" ]] && [[ -d $vscode ]]; then
        echo "Backing up vscode..."

        mkdir -p "$backupDir"
        # Backup config
        cp "$vscode/User/settings.json" "$backupDir"
        # Backup extensions
        echo "$(code --list-extensions)" > "$backupDir/extensions"
    elif [[ $1 -eq "restore" ]] && [[ -d "$backupDir" ]] && [[ $(command -v "code") ]]; then
        echo "Restoring vscode..."

        # Restore config
        cp -f "$backupDir/settings.json" "$vscode/User/"
        # Restore extensions
        while read -r extension; do
            code --install-extension $extension
        done < "$backupDir/extensions"
    fi
}

gnome() {
    local backupDir="$BACKUPDIR/gnome"

    if [[ $1 -eq "backup" ]]; then
        echo "Backing up gnome..."

        mkdir -p "$backupDir"
        # Backup gnome config
        echo "$(dconf dump /)" > "$backupDir/gnome"
        # Backup extensions
        cp -r "/home/$USER/.local/share/gnome-shell/extensions" "$backupDir"
    fi
}

ssh() {
    local backupDir="$BACKUPDIR/ssh"
    local sshDir="/home/$USER/.ssh"

    if [[ $1 -eq "backup" ]] && [[ -d $sshDir ]]; then
        echo "Backing up ssh..."

        mkdir -p "$backupDir"
        cp $sshDir/id_* "$backupDir"
    elif [[ $1 -eq "restore" ]] && [[ -d "$backupDir" ]]; then
        echo "Restoring ssh..."

        mkdir -p "$sshDir"
        cp -rf $backupDir/. "$sshDir/"
    fi
}

lutris() {
    local backupDir="$BACKUPDIR/lutris"
    local lutrisDir="/home/$USER/.local/share/lutris"
    local confDir="/home/$USER/.config/lutris"

    if [[ $1 -eq "backup" ]] && [[ -d $lutrisDir ]]; then
        echo "Backing up lutris..."

        mkdir -p "$backupDir/local"
        mkdir -p "$backupDir/conf"

        cp -r "$lutrisDir/pga.db" "$lutrisDir/runners" "$lutrisDir/banners" "$backupDir/local"
        cp -r "$confDir/system.yml" "$confDir/lutris.conf" "$confDir/games" "$confDir/runners" "$backupDir/conf"
    elif [[ $1 -eq "restore" ]] && [[ -d "$backupDir" ]] && [[ $(command -v "lutris") ]]; then
        echo "Restoring lutris..."

        mkdir -p "$lutrisDir"
        mkdir -p "$confDir"

        cp -rf $backupDir/local/. "$lutrisDir/"
        cp -rf $backupDir/conf/. "$confDir/"
    fi
}

qbittorent() {
    local backupDir="$BACKUPDIR/qbittorrent"
    local qbDir="/home/$USER/.local/share/data/qBittorrent/BT_backup"
    local qbConf="/home/$USER/.config/qBittorrent"

    if [[ $1 -eq "backup" ]] && [[ -d $qbDir ]]; then
        echo "Backing up qbittorrent..."

        mkdir -p "$backupDir"
        cp $qbDir/*.torrent $qbDir/*.fastresume "$qbConf/qBittorrent.conf" "$qbConf/qBittorrent-data.conf" "$backupDir"
    elif [[ $1 -eq "restore" ]] && [[ -d "$backupDir" ]] && [[ $(command -v "qbittorrent") ]]; then
        echo "Restoring qbittorrent..."

        mkdir -p "$qbDir"
        mkdir -p "$qbConf"

        cp $backupDir/*.torrent $backupDir/*.fastresume "$qbDir"
        cp -f "$backupDir/qBittorrent.conf" "$backupDir/qBittorrent-data.conf" "$qbConf"
    fi
}

keepassxc() {
    local backupDir="$BACKUPDIR/keepassxc"
    local kxDir="/home/$USER/.config/keepassxc"

    if [[ $1 -eq "backup" ]] && [[ -d $kxDir ]]; then
        echo "Backing up keepassxc..."

        mkdir -p "$backupDir"
        cp "$kxDir/keepassxc.ini" "$backupDir"
    elif [[ $1 -eq "restore" ]] && [[ -d "$backupDir" ]] && [[ $(command -v "keepassxc") ]]; then
        echo "Restoring keepassxc..."

        mkdir -p "$kxDir"
        cp -f "$backupDir/keepassxc.ini" "$kxDir/"
    fi
}

firefox() {
    local backupDir="$BACKUPDIR/firefox"
    local ffDir="/home/$USER/.mozilla/firefox"

    local reProfile="Path=([a-z0-9\.]+)"
    if [[ $1 -eq "backup" ]] && [[ $(cat "$ffDir/profiles.ini") =~ $reProfile ]]; then
        echo "Backing up firefox..."

        local pDir="${BASH_REMATCH[1]}"

        mkdir -p "$backupDir"
        cp -a "$ffDir/$pDir" "$backupDir/"
    fi
}

mpv() {
    local backupDir="$BACKUPDIR/mpv"
    local mpvDir="/home/$USER/.config/mpv"

    if [[ $1 -eq "backup" ]] && [[ -f "$mpvDir/mpv.conf" ]]; then
        echo "Backing up mpv..."

        mkdir -p "$backupDir"
        cp "$mpvDir/mpv.conf" "$backupDir/"
    elif [[ $1 -eq "restore" ]] && [[ -d "$backupDir" ]] && [[ $(command -v "mpv") ]]; then
        echo "Restoring mpv..."

        mkdir -p "$mpvDir"
        cp -f "$backupDir/mpv.conf" "$mpvDir/"
    fi
}

gnome_podcasts() {
    local backupDir="$BACKUPDIR/gnome-podcasts"
    local gpDir="/home/$USER/.var/app/org.gnome.Podcasts/data/gnome-podcasts"

    if [[ $1 -eq "backup" ]] && [[ -f "$gpDir/podcasts.db" ]]; then
        echo "Backing up gnome-podcasts..."

        mkdir -p "$backupDir"
        cp "$gpDir/podcasts.db" "$backupDir"
    elif [[ $1 -eq "restore" ]] && [[ $(flatpak list | grep org.gnome.Podcasts) ]]; then
        echo "Restoring gnome-podcasts..."

        mkdir -p "$gpDir"
        cp -f "$backupDir/podcasts.db" "$gpDir/"
    fi
}

retroarch() {
    local backupDir="$BACKUPDIR/retroarch"
    local raDir="/home/$USER/.var/app/org.libretro.RetroArch/config"

    if [[ $1 -eq "backup" ]] && [[ -d "$raDir" ]]; then
        echo "Backing up retroarch..."

        mkdir -p "$backupDir"
        cp -a "$raDir" "$backupDir/"
    elif [[ $1 -eq "restore" ]] && [[ $(flatpak list | grep org.libretro.RetroArch) ]]; then
        echo "Restoring retroarch..."

        mkdir -p "$raDir"
        cp -rf $backupDir/. "$raDir/"
    fi
}

declare -a FUNCS=(
    "vscode"
    "gnome"
    "ssh"
    "lutris"
    "qbittorent"
    "keepassxc"
    "firefox"
    "mpv"
    "gnome_podcasts"
    "retroarch"
)

case "$1" in
    "backup")
        rm -rf "$BACKUPDIR"

        for fn in "${FUNCS[@]}"; do $fn $1; done

        echo "Compressing..."
        tar cf - "$BACKUPDIR" | 7za a -si -txz -mx=9 "$BACKUPDIR.tar.xz"
        rm -rf "$BACKUPDIR"
        ;;
    "restore")
        if [[ ! -f "$BACKUPDIR.tar.xz" ]]; then
            echo "Error: no $BACKUPDIR.tar.xz found"
            exit 1
        fi

        echo "Uncompressing..."
        tar xf "$BACKUPDIR.tar.xz"

        for fn in "${FUNCS[@]}"; do $fn $1; done
        ;;
    *)
        echo "Usage: $0 {backup|restore}"
        exit 1
esac
