#!/usr/bin/env bash

#set -x
set -euo pipefail

echo "🔄 Installing static binary tools from internet"

# Detect distro
if [ -f /etc/os-release ]; then
    . /etc/os-release
    distro=$ID
else
    echo "❌ Unsupported system: no /etc/os-release 😢"
    echo "🔍 Please check your distribution and try again."
    exit 1
fi

mkdir -p $HOME/bin

PATH=$HOME/bin:$PATH

yq -r '.gz_tar_balls[] | "\(.name) \(.version_name) \(.link_to_bin) \(.download_url)"' install_from_http.yaml | while read NAME VERSION_NAME LINK_TO_BIN DOWNLOAD_URL; do
   echo $NAME
   echo $VERSION_NAME
   echo $LINK_TO_BIN
   echo $DOWNLOAD_URL


done 





# Update packages based on distro
case "$distro" in
    debian|ubuntu)
	echo "Detected Ubuntu/Debian"
	sudo apt update -y
	sudo apt install -y build-essential
	;;
    arch)
	echo "Detected Arch Linux"
	sudo pacman -Sy --noconfirm base-devel
	;;
    rhel|centos|fedora)
	echo "Detected RedHat/Fedora"
	sudo dnf groupinstall -y "Development Tools"
	;;
    *)
        echo "❌ Unsupported distro: $distro 😢"
        echo "❌ please install set of dev tools manually. ❌"
        exit 1
	;;
esac

echo "✅ Dev tools have been installed successfully"
