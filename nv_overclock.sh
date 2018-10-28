#!/bin/bash

coreOffset=208
memoryOffset=800

echo "Enter password for sudo"
read -s sudoPassword

# Set power limit to max
echo $sudoPassword | sudo -S nvidia-smi -pl 140

# Set core and memory clock
nvidia-settings -a GPUGraphicsClockOffsetAllPerformanceLevels=${coreOffset}
nvidia-settings -a GPUMemoryTransferRateOffsetAllPerformanceLevels=${memoryOffset}

if [[ $1 == "--startup" ]]; then
    DESKTOPDIR="/home/${USER}/.config/autostart"
    if [[ ! -d $DESKTOPDIR ]]; then
        mkdir $DESKTOPDIR
    fi
    DESKTOPFILE="${DESKTOPDIR}/nv-overclock.desktop"
    if [[ -f $DESKTOPFILE ]]; then
        rm $DESKTOPFILE
    fi
    echo "[Desktop Entry]" >> $DESKTOPFILE
    echo "Name=NvOverclock" >> $DESKTOPFILE
    echo "Type=Application" >> $DESKTOPFILE
    echo "Exec=sh -c \"sleep 10s; echo $sudoPassword | sudo -S nvidia-smi -pl 140; nvidia-settings -a GPUGraphicsClockOffsetAllPerformanceLevels=${coreOffset}; nvidia-settings -a GPUMemoryTransferRateOffsetAllPerformanceLevels=${memoryOffset}\"" >> $DESKTOPFILE
    echo "Created startup file $DESKTOPFILE"
    else
        echo "Use --startup switch to create a desktop file for autostart"
fi