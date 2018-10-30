#!/bin/bash

if [[ $UID != 0 ]]; then
    echo "Script must be run as root"
    exit 1
fi

# Enable RPM fusion
dnf install https://download1.rpmfusion.org/free/fedora/rpmfusion-free-release-$(rpm -E %fedora).noarch.rpm https://download1.rpmfusion.org/nonfree/fedora/rpmfusion-nonfree-release-$(rpm -E %fedora).noarch.rpm
# Enable negativo17 Nvidia repo
dnf config-manager --add-repo=https://negativo17.org/repos/fedora-nvidia.repo
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
declare -a PACKAGES=(
# Apps
    'calibre'
    'discord'
    'gnome-tweaks'
    'keepassxc'
    'lm_sensors'
    'nano'
    'p7zip'
    'qbittorrent'
    'unrar'
    'thefuck'
    'mpv'

# Dev
    'code'
    'qt-creator'
    'qt5-devel'
    'golang'

# Fonts/icons etc
    'google-roboto-fonts'
    'papirus-icon-theme'

# Nvidia and gaming
    'kernel-devel'
    'nvidia-driver'
    'nvidia-driver-cuda'
    'nvidia-settings'
    'nvidia-driver-libs.i686'
    'akmod-nvidia'
    'lutris'
    'wine'
    'steam'

)

# Flatpaks to install
declare -a FLATPAKS=(
    'com.google.AndroidStudio/x86_64/stable'
    'com.jgraph.drawio.desktop/x86_64/stable'
    'org.DolphinEmu.dolphin-emu/x86_64/stable'
    'org.libretro.RetroArch/x86_64/stable'
    'com.spotify.Client'
)

dnf install ${PACKAGES[@]}
flatpak install flathub ${FLATPAKS[@]}

# After nvidia driver install
grub2-mkconfig -o /boot/efi/EFI/fedora/grub.cfg
dracut --force
