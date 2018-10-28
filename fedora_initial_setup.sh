#!/bin/bash

if [[ $UID != 0 ]]; then
    echo "Script must be run as root"
    exit 1
fi

# Enable RPM fusion
dnf install https://download1.rpmfusion.org/free/fedora/rpmfusion-free-release-$(rpm -E %fedora).noarch.rpm https://download1.rpmfusion.org/nonfree/fedora/rpmfusion-nonfree-release-$(rpm -E %fedora).noarch.rpm
# Enable negativo17 Nvidia repo
dnf config-manager --add-repo=https://negativo17.org/repos/fedora-nvidia.repo
# Enable Lutris repo
dnf config-manager --add-repo https://download.opensuse.org/repositories/home:strycore/Fedora_$(rpm -E %fedora)/home:strycore.repo
# Enable vscode repo
rpm --import https://packages.microsoft.com/keys/microsoft.asc
sh -c 'echo -e "[code]\nname=Visual Studio Code\nbaseurl=https://packages.microsoft.com/yumrepos/vscode\nenabled=1\ngpgcheck=1\ngpgkey=https://packages.microsoft.com/keys/microsoft.asc" > /etc/yum.repos.d/vscode.repo'
# Enable papirus-icon-theme copr
dnf copr enable dirkdavidis/papirus-icon-theme

# Update cache
dnf makecache

# Enable flathub
flatpak remote-add --if-not-exists flathub https://flathub.org/repo/flathub.flatpakrepo

# Packages to install
declare -a PACKAGES (
    'calibre'
    'code'
    'discord'
    'gnome-tweaks'
    'google-roboto-fonts'
    'keepassxc'
    'lm_sensors'
    'lutris'
    'mpv'
    'nano'
    'kernel-devel'
    'nvidia-driver'
    'nvidia-driver-cuda'
    'nvidia-settings'
    'akmod-nvidia'
    'p7zip'
    'qbittorrent'
    'qt-creator'
    'qt5-devel'
    'steam'
    'unrar'
    'papirus-icon-theme'
)

declare -a FLATPAKS (
    'com.google.AndroidStudio/x86_64/stable'
    'com.jgraph.drawio.desktop/x86_64/stable'
    'org.DolphinEmu.dolphin-emu/x86_64/stable'
    'org.libretro.RetroArch/x86_64/stable'
)

dnf install ${PACKAGES[@]}
flatpak install ${FLATPAKS[@]}
