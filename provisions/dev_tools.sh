#!/bin/bash
set -euo pipefail

# --- Source section ---
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
source "${SCRIPT_DIR}/_utils.sh"

log INFO "Now executing $(basename "${0}")"

# --- Global variables check ---

# --- Hard prerequisites ---
check_commands_installed sudo || {
   log ERROR "❌ Missing required commands." >&2
   exit 1
}

# --- Main role logic ---

log INFO "🔄 Installing set of dev tools"

if distro=$(detect_linux_distro); then
   log INFO "✅ Detected distro: '$distro'"
else
   log INFO "❌ Failed to detect Linux distribution" >&2
   exit 1
fi

# Update packages based on distro
case "$distro" in
    debian|ubuntu)
	echo "Detected Ubuntu/Debian"
	sudo -E apt update -y
	sudo -E apt install -y build-essential
	;;
    arch)
	echo "Detected Arch Linux"
	sudo -E pacman -Sy --noconfirm base-devel
	;;
    rhel|centos|fedora)
	echo "Detected RedHat/Fedora"
	sudo -E dnf groupinstall -y "Development Tools"
	;;
    *)
        echo "❌ Unsupported distro: $distro 😢"
        echo "❌ please install set of dev tools manually. ❌"
        exit 1
	;;
esac

# --- return 0 if OK ---
log INFO "✅ Successfully installed dev tools"
exit 0
