#!/bin/bash

if [[ $UID == 0 ]]; then
    echo "Do not run as root"
    exit 1
fi

create_alias() {
    if [[ $(cat ~/.bashrc) =~ "alias $1=\"" ]]; then
        echo "Alias $1 already exists"
    else
        echo "alias $1=\"$2\"" >> ~/.bashrc
    fi
}

create_function() {
    if [[ $(cat ~/.bashrc) =~ "function $1()" ]]; then
        echo "Function $1 already exists"
    else
        printf "\nfunction %s() {\n %s\n}\n" "$1" "$2" >> ~/.bashrc
    fi
}

# Upd: update dnf and flatpaks
create_alias "upd" "dnf check-update --refresh; if [ \$? -eq 100 ]; then sudo dnf upgrade; fi; flatpak update"

# Aliases for shorter typing
create_alias ".." "cd .."
create_alias "c" "clear"

# Aliases for showing better output
create_alias "df" "df -h"
create_alias "free" "free -h"
create_alias "du" "du -h"
create_alias "ls" "ls -alhF --color=auto"

# Git aliases
create_function "pushall" \
'   git add -A
    local m
    read -p "Commit message: " m
    git commit -m "$m"
    git push'
