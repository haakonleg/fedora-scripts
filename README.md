# fedora-scripts
Personal scripts for fedora

fedora_perf_tweaks.sh is a script which enables several performance tweaks, like swappiness value, blk-mq, disabling watchdog timers, disabling spectre mitigations (useless for normal users), enabling periodic trim for SSD, disabling access time update for ext4 (noatime), enabling all sysrq key functions, changing some pulseaudio options and disabling mouse acceleration.

scheduled_backup.sh is a script for scheduling a daily backup of the home directory and /etc using systemd timer.

backup.sh is a script for backing up and later restoring the data and configurations of several applications.

tempmon.sh is a simple CPU/GPU temperature monitoring script.
