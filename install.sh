#!/usr/bin/bash

if command -v apt &>/dev/null; then
    sudo apt install ansible
    sudo apt install ansible-galaxy
elif command -v pacman &>/dev/null; then
    sudo pacman -S ansible
    sudo pacman -S ansible-galaxy
else
    echo "Could not find apt or pacman"
    exit 1
fi
