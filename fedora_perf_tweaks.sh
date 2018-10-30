#!/bin/bash

if [[ $UID != 0 ]]; then
    echo "Script must be run as root"
    exit 1
fi

# Config
GRUBCONFIG="/etc/default/grub"
GRUBEFI="/boot/efi/EFI/fedora/grub.cfg"
FSTAB="/etc/fstab"
SWAPPINESS_VAL=1

# Global vars
ORIGUSER=$(logname)
GRUBCHANGED=false

backup() {
    sudo -u $ORIGUSER cp $GRUBCONFIG grub.bak
    sudo -u $ORIGUSER cp $FSTAB fstab.bak
}

# Adds kernel paramenter $1 to /etc/default/grub
add_kernel_param() {
    for var in "$@"; do
        local grub=$(cat $GRUBCONFIG | grep "GRUB_CMDLINE_LINUX")
        local check="[[:space:]\"]${var}[[:space:]\"]"

        if [[ $grub =~ $check ]]; then
            printf "\t$var already set, skipping\n"
        else
            sed -i'' '/GRUB_CMDLINE_LINUX=/s/"$/ '$var'"/' $GRUBCONFIG
            GRUBCHANGED=true
        fi
    done
}

# Generate new grub.cfg
grub_make_config() {
    echo "Generating new grub.cfg"

    grub2-mkconfig -o $GRUBEFI
}

# Creates the file $1 with content of string array $2 if it does not exist
create_file() {
    if [[ -f $1 ]]; then
        printf "\t$1 already exists, skipping\n"
        return 1
    fi

    touch $1
    return 0
}

# Set swappiness value
swappiness() {
    echo "Setting swappiness value"

    local CURR=$(cat /proc/sys/vm/swappiness)
    if [[ CURR -eq SWAPPINESS_VAL ]]; then
        printf "\tSwappiness already set to $SWAPPINESS_VAL, skipping\n"
        return
    fi

    local SWAPPINESSFILE="/etc/sysctl.d/swappiness.conf"
    if create_file $SWAPPINESSFILE; then
        echo "vm.swappiness=$SWAPPINESS_VAL" > $SWAPPINESSFILE
        printf "\tWrote file $SWAPPINESSFILE\n"
    fi
}

# Enable blk_mq and create rules for schedulers
blk_mq() {
    echo "Setting up blk_mq and IO schedulers"

    add_kernel_param "scsi_mod.use_blk_mq=1"

    # Udev rule to set IO scheduler from https://wiki.archlinux.org/index.php/improving_performance#Changing_I.2FO_scheduler
    local UDEVFILE="/etc/udev/rules.d/60-ioschedulers.rules"
    declare -a UDEVRULES=(
        '# set scheduler for non-rotating disks'
        'ACTION=="add|change", KERNEL=="sd[a-z]|mmcblk[0-9]*|nvme[0-9]*", ATTR{queue/rotational}=="0", ATTR{queue/scheduler}="mq-deadline"'
        '# set scheduler for rotating disks'
        'ACTION=="add|change", KERNEL=="sd[a-z]", ATTR{queue/rotational}=="1", ATTR{queue/scheduler}="bfq"'
    )

    if create_file $UDEVFILE; then
        printf "%s\n" "${UDEVRULES[@]}" > $UDEVFILE
        printf "\tWrote file $UDEVFILE\n"
    fi
}

# Disable watchdog timers
# Normal users don't need this and it decreases performance
watchdog() {
    echo "Disabling watchdog timers"

    add_kernel_param "nowatchdog"
}

# Disable spectre mitigations
# Most of these mitigations are useless for normal users and only decrease performance
spectre() {
    echo "Disabling spectre mitigations"

    add_kernel_param "nopti" "nospectre_v2" "nospec_store_bypass_disable" "l1tf=off" "no_stf_barrier"

    # Prevent microcode from updating
    if [[ $(dnf list installed | grep "microcode_ctl" | wc -l) -gt 0 ]]; then
        printf "\tRemoving microcode_ctl\n"
        dnf remove microcode_ctl
        dracut --force
    else
        printf "\tmicrocode_ctl is not present on the system\n"
    fi
}

# Enable the fstrim.timer service which runs discard once a week
trim() {
    echo "Enabling periodic fstrim"

    systemctl enable fstrim.timer --now
}

# Disable access time update for ext4 filesystems
noatime() {
    echo "Disabling access time update (noatime)"

    sed -ri'' '/ext4/ {/noatime/! s/(defaults[a-z,]*)/\1,noatime/}' $FSTAB
    printf "\tWrote file $FSTAB\n"
}

# Enable all sysrq key functions
# Useful for when the system locks up, and you can use REISUB
sysrq() {
    echo "Enabling sysrq"

    local SYSRQFILE='/etc/sysctl.d/sysrq.conf'
    if create_file $SYSRQFILE; then
        printf "%s\n" "kernel.sysrq = 1" > $SYSRQFILE
        printf "\t Wrote file $SYSRQFILE\n"
    fi
}

# Change some pulseaudio settings to avoid resampling when possible and set a better resample method
pulseaudio() {
    echo "Setting pulseaudio options"

    local PADIR="/home/${ORIGUSER}/.config/pulse"
    local PAFILE="${PADIR}/daemon.conf"

    if [[ ! -d $PADIR ]]; then
        mkdir $PADIR
    fi

    if [[ ! -f $PAFILE ]]; then
        sudo -u $ORIGUSER touch $PAFILE

        declare -a PAOPTS=(
            'resample-method = speex-float-5'
            'avoid-resampling = true'
            'flat-volumes = no'
            'default-sample-format = s16le'
            'alternate-sample-rate = 48000'
        )

        printf "%s\n" "${PAOPTS[@]}" > $PAFILE
        printf "\tWrote file $PAFILE\n"

    else
        printf "\t$PAFILE already exists, skipping\n"
    fi
}

# Disable mouse acceleration, which is a terrible thing to have
nomouseaccel() {
    echo "Disabling mouse acceleration"

    sudo -u $ORIGUSER gsettings set org.gnome.desktop.peripherals.mouse accel-profile flat

    local MOUSEACCELFILE='/etc/X11/xorg.conf.d/50-mouse-acceleration.conf'
    declare -a MOUSEACCELOPTS=(
        'Section "InputClass"'
        '    Identifier "My Mouse"'
        '    Driver "libinput"'
        '    MatchIsPointer "yes"'
        '    Option "AccelProfile" "flat"'
        'EndSection'
    )

    if create_file $MOUSEACCELFILE; then
        printf "%s\n" "${MOUSEACCELOPTS[@]}" > $MOUSEACCELFILE
        printf "\tWrote file $MOUSEACCELFILE\n"
    fi
}

cpugov() {
    echo "Enabling CPU performance governor"

    # Install kernel-tools if needed
    if [[ $(dnf list installed | grep "kernel-tools" | wc -l) -lt 1 ]]; then
        dnf install kernel-tools
    fi

    # Create systemd service to set at boot
    local UNITFILE='/etc/systemd/system/cpugov.service'
    declare -a CPUGOV=(
        '[Unit]'
        'Description=Set CPU governor'
        ''
        '[Service]'
        'Type=oneshot'
        'ExecStart=/usr/bin/cpupower -c all frequency-set -g performance'
        ''
        '[Install]'
        'WantedBy=multi-user.target'
    )

    if create_file $UNITFILE; then
        printf "%s\n" "${CPUGOV[@]}" > $UNITFILE
        printf "\tWrote file $UNITFILE\n"

        systemctl daemon-reload
        systemctl enable cpugov --now
    fi
}

fonts() {
    echo "Setting font configuration"

    sudo -u $ORIGUSER gsettings set org.gnome.settings-daemon.plugins.xsettings antialiasing rgba
    sudo -u $ORIGUSER gsettings set org.gnome.settings-daemon.plugins.xsettings hinting none

    declare -a FONTSCONFIG=(
        '<?xml version="1.0"?>'
        '<!DOCTYPE fontconfig SYSTEM "fonts.dtd">'
        '<fontconfig>'
        '  <match target="font">'
        '    <edit name="antialias" mode="assign">'
        '      <bool>true</bool>'
        '    </edit>'
        '  </match>'
        '  <match target="font">'
        '    <edit name="hinting" mode="assign">'
        '      <bool>true</bool>'
        '    </edit>'
        '  </match>'
        '  <match target="font">'
        '    <edit name="autohint" mode="assign">'
        '      <bool>false</bool>'
        '    </edit>'
        '  </match>'
        '  <match target="font">'
        '    <edit name="hintstyle" mode="assign">'
        '      <const>hintnone</const>'
        '    </edit>'
        '  </match>'
        '  <match target="font">'
        '    <edit name="rgba" mode="assign">'
        '      <const>rgb</const>'
        '    </edit>'
        '  </match>'
        '  <match target="font">'
        '    <edit name="lcdfilter" mode="assign">'
        '      <const>lcddefault</const>'
        '    </edit>'
        '  </match>'
        '</fontconfig>'
    )

    printf "%s\n" "${FONTSCONFIG[@]}" > "/etc/fonts/local.conf"
}

backup
swappiness
spectre
blk_mq
watchdog
trim
noatime
sysrq
pulseaudio
nomouseaccel
cpugov
fonts
if $GRUBCHANGED; then
    grub_make_config
fi
