#!/usr/bin/env bash
set -Eeuo pipefail

# --- Source section ---
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
source "${SCRIPT_DIR}/_utils.sh"

log INFO "Now executing $(basename "${0}")"

# --- Knobs forwarded to package-mgr ---
PKG_TIMEOUT="${PKG_TIMEOUT:-600}"
CUSTOM_PKG_FLAGS="${CUSTOM_PKG_FLAGS:-}"

# --- Hard prerequisites ---
check_commands_installed sudo || { log ERROR "❌ Missing required commands."; exit 1; }

# --- Main role logic ---
log INFO "🔄 Installing set of dev tools"

if distro=$(detect_linux_distro); then
   log INFO "✅ Detected distro: '$distro'"
else
   log ERROR "❌ Failed to detect Linux distribution"; exit 1
fi

PKG_MGR_BIN="${SCRIPT_DIR}/package-mgr"
[[ -x "$PKG_MGR_BIN" ]] || { log ERROR "❌ '${PKG_MGR_BIN}' not found or not executable."; exit 1; }

# Map package names per family, but always invoke via package-mgr
case "$distro" in
  debian|ubuntu)
    PKGS="build-essential,git"
    ;;
  arch)
    PKGS="base-devel,git"
    ;;
  rhel|centos|rocky|almalinux|fedora)
    # dnf groupinstall is not generic; use an explicit toolchain set
    base_pkgs="gcc,gcc-c++,make,automake,autoconf,libtool,gettext,patch,pkgconf"
    PKGS="${base_pkgs},git"
    ;;
  *)
    log ERROR "❌ Unsupported distro: $distro"; exit 1 ;;
esac

PM_CMD=( sudo -E "$PKG_MGR_BIN" --install "$PKGS" --timeout "$PKG_TIMEOUT" --auto-confirm )
[[ -n "$CUSTOM_PKG_FLAGS" ]] && PM_CMD+=( --custom-flags "$CUSTOM_PKG_FLAGS" )

"${PM_CMD[@]}"

log INFO "✅ Successfully installed dev tools"
exit 0

