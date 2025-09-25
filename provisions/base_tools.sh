#!/usr/bin/env bash
set -Eeuo pipefail

# --- Source section ---
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
source "${SCRIPT_DIR}/_utils.sh"

log INFO "Now executing $(basename "${0}")"

# --- Global variables / knobs ---
YQ_VERSION="${YQ_VERSION:-4.45.1}"
PKG_TIMEOUT="${PKG_TIMEOUT:-600}"                 # forwarded to package-mgr --timeout
CUSTOM_PKG_FLAGS="${CUSTOM_PKG_FLAGS:-}"          # forwarded to package-mgr --custom-flags "<...>"

# --- Hard prerequisites ---
check_commands_installed sudo mkdir pcurl_wrapper test ln || {
   log ERROR "❌ Missing required commands."; exit 1; }

# --- Main role logic ---
log INFO "🔄 Installing set of base tools"

if distro=$(detect_linux_distro); then
   log INFO "✅ Detected distro: $distro"
else
   log ERROR "❌ Failed to detect Linux distribution"; exit 1
fi

# Ensure package-mgr exists
PKG_MGR_BIN="${SCRIPT_DIR}/package-mgr"
if [[ ! -x "$PKG_MGR_BIN" ]]; then
  log ERROR "❌ '${PKG_MGR_BIN}' not found or not executable."; exit 1
fi

# Cross-distro package set (names align across Debian/Arch/Fedora families)
PKGS="htop,net-tools,xclip,tmux,jq,curl,file"

# Build package-mgr command
PM_CMD=( sudo -E "$PKG_MGR_BIN" --install "$PKGS" --timeout "$PKG_TIMEOUT" --auto-confirm )
[[ -n "$CUSTOM_PKG_FLAGS" ]] && PM_CMD+=( --custom-flags "$CUSTOM_PKG_FLAGS" )

"${PM_CMD[@]}"

# --- essentials from HTTP ----------------------------------------------------
mkdir -p "$HOME/bin"

# install yq (honors DISABLE_IPV6 via curl flag)
if [[ ! -f "$HOME/bin/yq-versions/v${YQ_VERSION}/yq_linux_amd64" ]]; then
   mkdir -p "$HOME/bin/yq-versions/v${YQ_VERSION}"
   pcurl_wrapper -fL  \
     -o "$HOME/bin/yq-versions/v${YQ_VERSION}/yq_linux_amd64" \
     "https://github.com/mikefarah/yq/releases/download/v${YQ_VERSION}/yq_linux_amd64"
   chmod +x "$HOME/bin/yq-versions/v${YQ_VERSION}/yq_linux_amd64"
   [[ -L "$HOME/bin/yq" ]] && unlink "$HOME/bin/yq"
   ln -s "$HOME/bin/yq-versions/v${YQ_VERSION}/yq_linux_amd64" "$HOME/bin/yq"
fi

log INFO "✅ Successfully installed base tools"
exit 0

