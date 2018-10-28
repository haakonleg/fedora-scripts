#!/bin/bash

if [[ $UID != 0 ]]; then
    echo "Script must be run as root"
    exit 1
fi

coreOffset=208
memoryOffset=800

# Set power limit to max
nvidia-smi -pl 140

# Set core and memory clock
nvidia-settings -a GPUGraphicsClockOffsetAllPerformanceLevels=${coreOffset} -a GPUMemoryTransferRateOffsetAllPerformanceLevels=${memoryOffset}

if [[ $1 == "--startup" ]]; then
    UNITFILE='/etc/systemd/system/nvidia-oc.service'
    declare -a NVIDIA_OC=(
        '[Unit]'
        'Description=Overclock Nvidia card'
        ''
        '[Service]'
        'Type=oneshot'
        "ExecStart=/usr/bin/bash -c '/usr/bin/nvidia-smi -pl 140; until /usr/bin/nvidia-settings -a GPUGraphicsClockOffsetAllPerformanceLevels=${coreOffset} -a GPUMemoryTransferRateOffsetAllPerformanceLevels=${memoryOffset}; do sleep 5; done'"
        "Environment=DISPLAY=${DISPLAY}"
        ''
        '[Install]'
        'WantedBy=graphical.target'
    )

    printf "%s\n" "${NVIDIA_OC[@]}" > $UNITFILE
    systemctl daemon-reload
    systemctl enable nvidia-oc --now
    else
        echo "Use --startup switch to create a desktop file for autostart"
fi
