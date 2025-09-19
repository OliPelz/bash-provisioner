#!/bin/bash
set -euo pipefail

# --- Source section ---
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
source "${SCRIPT_DIR}/_utils.sh"

log INFO "Now executing $(basename "${0}")"

# --- Global variables check ---
NEOVIM_VERSION="v${NEOVIM_VERSION:-0.10.2}"

# --- Hard prerequisites ---
check_commands_installed git sudo make mkdir ln || {
   log ERROR "❌ Missing required commands." >&2
   exit 1
}

# --- Main role logic ---

log INFO "🔄 Installing Neovim version: $NEOVIM_VERSION"

if distro=$(detect_linux_distro); then
   log INFO "✅ Detected distro: $distro"
else
   log INFO "❌ Failed to detect Linux distribution" >&2
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

src_dir="$HOME/bin/neovim_versions/$NEOVIM_VERSION/src"
install_dir="$HOME/bin/neovim_versions/$NEOVIM_VERSION"
symlink_path="$HOME/bin/neovim"

# Check if desired version is already installed
if [[ -x "$install_dir/bin/nvim" ]]; then
    installed_version="$("$install_dir/bin/nvim" --version | awk 'NR==1{print $2}')"
    if [[ "$installed_version" == "$NEOVIM_VERSION" ]]; then
        log INFO "😎 Neovim is already installed in version $installed_version at $install_dir...bailing out"
        exit 0
    else
        log INFO "Found Neovim at $install_dir but version $installed_version (want $NEOVIM_VERSION); continuing with build."
    fi
fi

mkdir -p "$HOME/bin/neovim_versions/$NEOVIM_VERSION"

# Clone Neovim repo if not already
if ! git --git-dir=$src_dir/.git fsck --full 2>&1  >/dev/null; then
    git clone -b $NEOVIM_VERSION --depth 1 https://github.com/neovim/neovim.git "$src_dir"
fi

# see https://github.com/neovim/neovim/issues/9743#issuecomment-473658606

make -C "$src_dir" clean
make -C "$src_dir" \
        CMAKE_INSTALL_PREFIX="$install_dir" \
        CMAKE_BUILD_TYPE=RelWithDebInfo \
        CMAKE_EXTRA_FLAGS="-DCMAKE_INSTALL_MANDIR=$install_dir/share/man" 

# NOTE: adapting the man path with custom man dir used here, will be done
#       using MANPATH in dotfiles, not here

make -C "$src_dir" install

# Ensure bin directory exists and link neovim binary
mkdir -p "$HOME/bin"
[ -L "$symlink_path" ] && unlink "$symlink_path"
ln -sf "$install_dir/bin/nvim" "$symlink_path"

# --- return 0 if OK ---
log INFO "🔄 Successfully installed Neovim with version: $NEOVIM_VERSION"
exit 0
