#!/usr/bin/bash

set -e

echo "Detecting package manager..."

if command -v apt &>/dev/null; then
    echo "Using apt package manager"
    if ! command -v ansible &>/dev/null; then
        echo "Installing Ansible via apt..."
        sudo apt update
        sudo apt install -y ansible ansible-core
    else
        echo "Ansible already installed via apt"
    fi
elif command -v pacman &>/dev/null; then
    echo "Using pacman package manager"
    if ! command -v ansible &>/dev/null; then
        echo "Installing Ansible via pacman..."
        sudo pacman -S --noconfirm --needed ansible ansible-core
    else
        echo "Ansible already installed via pacman"
    fi
else
    echo "ERROR: Could not find apt or pacman package manager"
    echo "Supported package managers: apt, pacman"
    exit 1
fi

echo "Ansible installation completed successfully!"