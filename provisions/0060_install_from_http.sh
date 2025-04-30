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

export PATH=$HOME/bin:$PATH

# installing gzip tar balls from http
yq -r '.gz_tar_balls[] | "\(.link_name) \(.extract_dir) \(.path_to_bin) \(.download_url)"' install_from_http.yaml | while read -r LINK_NAME EXTRACT_DIR PATH_TO_BIN DOWNLOAD_URL; do
   DEST_DIR=$HOME/bin/$LINK_NAME-versions/$EXTRACT_DIR
   if ! test -f $DEST_DIR/$PATH_TO_BIN; then
      mkdir -p $DEST_DIR
      # download and put the archives content to a new top-level dir
      # Hint: the --strip-components=1 option removes the top-level directory from the file paths
      curl -L "$DOWNLOAD_URL" | tar -xz --strip-components=1 -C "$DEST_DIR"
      
      # force re-creation of link
      test -L $HOME/bin/$LINK_NAME && unlink $HOME/bin/$LINK_NAME
      ln -sf $DEST_DIR/$PATH_TO_BIN $HOME/bin/$LINK_NAME
      
      echo "downloaded binary $LINK_NAME, installed under $HOME/bin/$LINK_NAME linking to $DEST_DIR/$PATH_TO_BIN"
   fi
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
