# provisions/install_libs.sh
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

# --- Detect distro ---
if distro=$(detect_linux_distro); then
  log INFO "✅ Detected distro: '${distro}'"
else
  log ERROR "❌ Failed to detect Linux distribution"; exit 1
fi

# --- Ensure package-mgr is available ---
PKG_MGR_BIN="${SCRIPT_DIR}/package-mgr"
[[ -x "$PKG_MGR_BIN" ]] || { log ERROR "❌ '${PKG_MGR_BIN}' not found or not executable."; exit 1; }

# --- Map packages (runtime libxml2 everywhere) ---
case "$distro" in
  debian|ubuntu) PKGS="libxml2" ;;
  arch)          PKGS="libxml2" ;;
  rhel|centos|rocky|almalinux|fedora) PKGS="libxml2" ;;
  *) log ERROR "❌ Unsupported distro: $distro"; exit 1 ;;
esac

log INFO "📦 Installing libraries: ${PKGS//,/ }"

PM_CMD=( sudo -E "$PKG_MGR_BIN" --install "$PKGS" --timeout "$PKG_TIMEOUT" --auto-confirm )
[[ -n "${CUSTOM_PKG_FLAGS}" ]] && PM_CMD+=( --custom-flags "$CUSTOM_PKG_FLAGS" )

"${PM_CMD[@]}"

# --- Post-install sanity check for libxml2 runtime (libxml2.so.*) ---
if command -v ldconfig >/dev/null 2>&1; then
  if ! ldconfig -p 2>/dev/null | awk '{print $1}' | grep -qE '^libxml2\.so(\.|$)'; then
    log ERROR "❌ libxml2 runtime library not found in loader cache after install."
    exit 1
  fi
else
  # Fallback: quick path scan
  if ! compgen -G "/lib*/libxml2.so*" >/dev/null && \
     ! compgen -G "/usr/lib*/libxml2.so*" >/dev/null && \
     ! compgen -G "/usr/local/lib*/libxml2.so*" >/devnull; then
    log ERROR "❌ libxml2 runtime library not found on filesystem after install."
    exit 1
  fi
fi

log INFO "✅ Successfully installed libraries"
exit 0
