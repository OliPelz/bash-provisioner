#!/usr/bin/env bash

#set -x
set -euo pipefail

# install neovim in specific version
version="v0.10.2"

echo "🔄 Installing Neovim version: $version"

src_dir="$HOME/bin/neovim_versions/$version/src"
install_dir="$HOME/bin/neovim_versions/$version"
symlink_path="$HOME/bin/neovim"

# Detect distro
if [ -f /etc/os-release ]; then
    . /etc/os-release
    distro=$ID
else
    echo "❌ Unsupported system: no /etc/os-release 😢"
    echo "🔍 Please check your distribution and try again."
    exit 1
fi

# install packages needed to build neovim
case "$distro" in
    debian|ubuntu)
        echo "Detected Ubuntu/Debian"
        sudo apt update -y
        sudo apt -y install ninja-build gettext cmake unzip curl build-essential libtool libtool-bin autoconf automake pkg-config liblua5.1-0-dev
        ;;
    arch)
        echo "Detected Arch Linux"
        sudo pacman -Sy --noconfirm base-devel cmake unzip ninja gettext lua
        ;;
    rhel|centos|fedora)
        echo "Detected RedHat/Fedora"
        sudo dnf install -y ninja-build cmake gcc gcc-c++ make gettext libtool autoconf automake pkgconfig lua-devel
        ;;
    *)
        echo "❌ Unsupported distro: $distro 😢"
        echo "❌ please install neovim dependencies manually. ❌"
        exit 1
	;;
esac

# Check if desired version is already installed
if [ -x "$install_dir/bin/nvim" ]; then
    echo "😎 Neovim $version is already installed at $install_dir...bailing out"
    exit 1
fi

mkdir -p "$HOME/bin/neovim_versions/$version"

# Clone Neovim repo if not already
if ! git --git-dir=$src_dir/.git fsck --full 2>&1  >/dev/null; then
    git clone -b $version --depth 1 https://github.com/neovim/neovim.git "$src_dir"
fi

# see https://github.com/neovim/neovim/issues/9743#issuecomment-473658606

make -C "$src_dir" clean
make -C "$src_dir" \
        CMAKE_INSTALL_PREFIX="$install_dir" \
        CMAKE_BUILD_TYPE=RelWithDebInfo \
        CMAKE_EXTRA_FLAGS="-DCMAKE_INSTALL_MANDIR=$install_dir/share/man" 

make -C "$src_dir" install

# Ensure bin directory exists and link neovim binary
mkdir -p "$HOME/bin"
ln -sf "$install_dir/bin/nvim" "$symlink_path"

echo "✅ Neovim $version is installed and linked at $symlink_path"
