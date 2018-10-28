#!/bin/bash

if [[ $1 == "--alias" ]]; then
    SCRIPTPATH=$(realpath $0)
    echo "alias upd=\"${SCRIPTPATH}\"" >> ~/.bashrc
    echo "Created bash alias 'upd' for this script"
    exit 0
fi

# DNF
dnf check-update --refresh
if [[ $? -eq 100 ]]; then
    sudo dnf upgrade
fi

# Flatpak
if [ -f "/usr/bin/flatpak" ]; then
    printf "\n\nUpdating flatpaks...\n"
    flatpak update
fi
