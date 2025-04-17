#!/usr/bin/env bash
set -euo pipefail

# Detect distro
if [ -f /etc/os-release ]; then
    . /etc/os-release
    distro=$ID
else
    echo "Unsupported system: no /etc/os-release"
    exit 1
fi

echo "Detected distro: $distro"

# Record current kernel and glibc versions
current_kernel=$(uname -r)
current_glibc=$(ldd --version | head -n1)

echo "Current kernel: $current_kernel"
echo "Current glibc:  $current_glibc"

# Update packages based on distro
case "$distro" in
    debian|ubuntu)
        echo "Detected Ubuntu/Debian"
        sudo apt update
        sudo apt -y full-upgrade
        sudo apt -y autoremove
        ;;
    arch)
        echo "Detected Arch Linux"
        sudo pacman -Syu --noconfirm
        ;;
    rhel|centos|fedora)
        echo "Detected RedHat/Fedora"
        sudo dnf -y upgrade
        ;;
    *)
        echo "Unsupported distro: $distro"
        exit 1
        ;;
esac

# Check new kernel and glibc versions
new_kernel=$(uname -r)
new_glibc=$(ldd --version | head -n1)

echo "New kernel: $new_kernel"
echo "New glibc:  $new_glibc"

# Determine if reboot is needed
# i figured this is if kernel or glibc is updated
reboot_required=false

if [ "$current_kernel" != "$new_kernel" ]; then
    echo "Kernel updated."
    reboot_required=true
fi

if [ "$current_glibc" != "$new_glibc" ]; then
    echo "glibc updated."
    reboot_required=true
fi

if [ "$reboot_required" = true ]; then
    echo "Rebooting system...you got 20 seconds to abort this now (CTRL+c)"
    echo "Please restart this script after reboot"
    sleep 20
    sudo reboot
else
    echo "No reboot required."
fi
