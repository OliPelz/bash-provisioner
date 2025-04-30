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
        sudo apt install -y htop net-tools xclip tmux jq curl
        ;;
    arch)
        echo "Detected Arch Linux"
        sudo pacman -Sy --noconfirm htop net-tools xclip tmux jq curl
        ;;
    rhel|centos|fedora)
        echo "Detected RedHat/Fedora"
        sudo dnf install -y htop net-tools xclip tmux jq curl
        ;;
    *)
        echo "❌ Unsupported distro: $distro 😢"
        echo "❌ please install set of base tools manually. ❌"
        exit 1
        ;;
esac

# some essential binaries in the system we need to install from HTTP
mkdir -p $HOME/bin


# install yq
if ! test -f $HOME/bin/yq-versions/v.4.45.1/yq_linux_amd64; then
   mkdir -p $HOME/bin/yq-versions/v4.45.1
   curl -o $HOME/bin/yq-versions/v.4.45.1/yq_linux_amd64 https://github.com/mikefarah/yq/releases/download/v4.45.1/yq_linux_amd64
   test -L $HOME/bin/yq && unlink $HOME/bin/yq
   ln -s $HOME/bin/yq-versions/v.4.45.1/yq_linux_amd64 $HOME/bin/yq
fi

echo "✅ Base tools have been installed successfully"
