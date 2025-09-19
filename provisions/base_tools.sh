#!/bin/bash
set -euo pipefail

# --- Source section ---
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
source "${SCRIPT_DIR}/_utils.sh"

log INFO "Now executing $(basename "${0}")"

# --- Global variables check ---
YQ_VERSION="${YQ_VERSION:-4.45.1}"

# --- Hard prerequisites ---
check_commands_installed sudo mkdir curl test ln || {
   log ERROR "❌ Missing required commands." >&2
   exit 1
}

# --- Main role logic ---

log INFO "🔄 Installing set of base tools"

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
mkdir -p "$HOME/bin"

# install yq, we need this before everything else
if ! test -f "$HOME/bin/yq-versions/v${YQ_VERSION}/yq_linux_amd64"; then
   mkdir -p "$HOME/bin/yq-versions/v${YQ_VERSION}"
   curl -fL -o "$HOME/bin/yq-versions/v${YQ_VERSION}/yq_linux_amd64" "https://github.com/mikefarah/yq/releases/download/v${YQ_VERSION}/yq_linux_amd64"
   chmod +x "$HOME/bin/yq-versions/v${YQ_VERSION}/yq_linux_amd64"
   test -L "$HOME/bin/yq" && unlink "$HOME/bin/yq"
   ln -s "$HOME/bin/yq-versions/v${YQ_VERSION}/yq_linux_amd64" "$HOME/bin/yq"
fi

# --- return 0 if OK ---
log INFO "✅ Successfully installed base tools"
exit 0
