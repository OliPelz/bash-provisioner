#!/usr/bin/env bash

#set -x
set -euo pipefail

echo "🔄 Installing set of base tools"

# Detect distro
if [ -f /etc/os-release ]; then
    . /etc/os-release
    distro=$ID
else
    echo "❌ Unsupported system: no /etc/os-release 😢"
    echo "🔍 Please check your distribution and try again."
    exit 1
fi

# Update packages based on distro
case "$distro" in
    debian|ubuntu)
        echo "Detected Ubuntu/Debian"
        sudo apt update -y
        sudo apt install -y htop net-tools xclip tmux jq
        ;;
    arch)
        echo "Detected Arch Linux"
        sudo pacman -Sy --noconfirm htop net-tools xclip tmux jq
        ;;
    rhel|centos|fedora)
        echo "Detected RedHat/Fedora"
        sudo dnf install -y htop net-tools xclip tmux jq
        ;;
    *)
        echo "❌ Unsupported distro: $distro 😢"
        echo "❌ please install set of base tools manually. ❌"
        exit 1
        ;;
esac

echo "✅ Base tools have been installed successfully"
