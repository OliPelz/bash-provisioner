#!/usr/bin/env bash

#set -x
set -euo pipefail

echo "Installing set of base tools"

# Detect distro
if [ -f /etc/os-release ]; then
    . /etc/os-release
    distro=$ID
else
    echo "Unsupported system: no /etc/os-release"
    exit 1
fi

# Update packages based on distro
case "$distro" in
    debian|ubuntu)
        echo "Detected Ubuntu/Debian"
        sudo apt update -y
        sudo apt install -y htop net-tools build-essential xclip
        ;;
    arch)
        echo "Detected Arch Linux"
        sudo pacman -Sy --noconfirm htop net-tools base-devel xclip
        ;;
    rhel|centos|fedora)
        echo "Detected RedHat/Fedora"
        sudo dnf install -y htop net-tools xclip
        sudo dnf groupinstall -y "Development Tools"
        ;;
    *)
        echo "Unsupported distro: $distro"
        echo "Unsupported OS — please install build tools and dependencies manually."
        exit 1
        ;;
esac

echo "✅ Base tools have been installed successfully"
