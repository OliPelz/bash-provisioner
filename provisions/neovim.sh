#!/usr/bin/env bash
set -Eeuo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
source "${SCRIPT_DIR}/_utils.sh"

log INFO "Now executing $(basename "${0}")"

NEOVIM_VERSION="v${NEOVIM_VERSION:-0.10.2}"
PKG_TIMEOUT="${PKG_TIMEOUT:-600}"
CUSTOM_PKG_FLAGS="${CUSTOM_PKG_FLAGS:-}"

check_commands_installed git sudo make mkdir ln || {
   log ERROR "❌ Missing required commands."; exit 1; }

log INFO "🔄 Installing Neovim version: $NEOVIM_VERSION"

if distro=$(detect_linux_distro); then
   log INFO "✅ Detected distro: $distro"
else
   log ERROR "❌ Failed to detect Linux distribution"; exit 1
fi

PKG_MGR_BIN="${SCRIPT_DIR}/package-mgr"
[[ -x "$PKG_MGR_BIN" ]] || { log ERROR "❌ '${PKG_MGR_BIN}' not found or not executable."; exit 1; }

# per-distro dependency names, but always installed via package-mgr
case "$distro" in
  debian|ubuntu)
    PKGS="ninja-build,gettext,cmake,unzip,curl,build-essential,libtool,libtool-bin,autoconf,automake,pkg-config,liblua5.1-0-dev"
    ;;
  arch)
    PKGS="base-devel,cmake,unzip,ninja,gettext,lua"
    ;;
  rhel|centos|rocky|almalinux|fedora)
    PKGS="ninja-build,cmake,gcc,gcc-c++,make,gettext,libtool,autoconf,automake,pkgconfig,lua-devel"
    ;;
  *) log ERROR "❌ Unsupported distro: $distro"; exit 1 ;;
esac

PM_CMD=( sudo -E "$PKG_MGR_BIN" --install "$PKGS" --timeout "$PKG_TIMEOUT" --auto-confirm )
[[ -n "$CUSTOM_PKG_FLAGS" ]] && PM_CMD+=( --custom-flags "$CUSTOM_PKG_FLAGS" )
"${PM_CMD[@]}"

src_dir="$HOME/bin/neovim_versions/$NEOVIM_VERSION/src"
install_dir="$HOME/bin/neovim_versions/$NEOVIM_VERSION"
symlink_path="$HOME/bin/neovim"

if [[ -x "$install_dir/bin/nvim" ]]; then
  installed_version="$("$install_dir/bin/nvim" --version | awk 'NR==1{print $2}')"
  if [[ "$installed_version" == "$NEOVIM_VERSION" ]]; then
    log INFO "😎 Neovim is already $installed_version at $install_dir...bailing out"
    exit 0
  else
    log INFO "Found Neovim $installed_version (want $NEOVIM_VERSION); rebuilding."
  fi
fi

mkdir -p "$HOME/bin/neovim_versions/$NEOVIM_VERSION"
if ! git --git-dir="$src_dir/.git" fsck --full >/dev/null 2>&1; then
  git clone -b "$NEOVIM_VERSION" --depth 1 https://github.com/neovim/neovim.git "$src_dir"
fi

make -C "$src_dir" clean
make -C "$src_dir" \
  CMAKE_INSTALL_PREFIX="$install_dir" \
  CMAKE_BUILD_TYPE=RelWithDebInfo \
  CMAKE_EXTRA_FLAGS="-DCMAKE_INSTALL_MANDIR=$install_dir/share/man"
make -C "$src_dir" install

mkdir -p "$HOME/bin"
[[ -L "$symlink_path" ]] && unlink "$symlink_path"
ln -sf "$install_dir/bin/nvim" "$symlink_path"

log INFO "🔄 Successfully installed Neovim with version: $NEOVIM_VERSION"
exit 0

