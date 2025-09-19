#!/bin/bash
set -euo pipefail

# --- Source section ---
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
source "${SCRIPT_DIR}/_utils.sh"

log INFO "Now executing $(basename "${0}")"

# --- Global variables check ---
UPDATE_ALLOW_REBOOT=${UPDATE_ALLOW_REBOOT:-true}


# --- Hard prerequisites ---
check_commands_installed uname ldd sudo || {
   log ERROR "❌ Missing required commands." >&2
   exit 1
}

# --- Main role logic ---

log INFO "🔄 Updating system packages"

# Record current kernel and glibc versions
current_kernel=$(uname -r)
current_glibc=$(ldd --version | head -n1)

log INFO "Current kernel: $current_kernel"
log INFO "Current glibc:  $current_glibc"

if distro=$(detect_linux_distro); then
   log INFO "✅ Detected distro: $distro"
else
   log INFO "❌ Failed to detect Linux distribution" >&2
   exit 1
fi

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
    rhel|centos|rocky|almalinux|fedora)
        echo "Detected RedHat/Fedora"
        sudo dnf -y upgrade
        ;;
    *)
        echo "❌ Unsupported distro: $distro 😢"
        exit 1
        ;;
esac

echo "✅ System packages update complete!"

# Check new kernel and glibc versions
new_kernel=$(uname -r)
new_glibc=$(ldd --version | head -n1)

log INFO "New kernel (after update): $new_kernel"
log INFO "New glibc (after update):  $new_glibc"

# Determine if reboot is needed
# i figured this is if kernel or glibc is updated
reboot_required=false

if [ "$current_kernel" != "$new_kernel" ]; then
log INFO "Kernel updated (versions have changed)"
reboot_required=true
fi

if [ "$current_glibc" != "$new_glibc" ]; then
    log INFO "glibc updated (versions have changed)"
    reboot_required=true
fi

if [ "$reboot_required" = true ]; then
    if [ "${UPDATE_ALLOW_REBOOT:-}" = "1" ]; then
        log INFO "🚀✨ Rebooting system ✨🚀"
        log INFO "...you got 20 seconds to abort this now (CTRL+c)"
        sleep 20
        sudo reboot
    else
        log INFO "Reboot required but skipped (set UPDATE_ALLOW_REBOOT=1 to allow)."
    fi
else
    log INFO "🎉 No reboot required."
fi


# --- return 0 if OK ---
log INFO "✅ Successfully updated system packages"
exit 0
