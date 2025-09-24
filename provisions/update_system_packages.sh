#!/usr/bin/env bash
set -Eeuo pipefail

glibc_info() {
: '
v0.01
'
  # Prefer getconf (returns "glibc 2.xx"), fall back to parsing ldd.
  if command -v getconf >/dev/null 2>&1; then
    if getconf GNU_LIBC_VERSION >/dev/null 2>&1; then
      # "glibc 2.39" -> print just "2.39"
      getconf GNU_LIBC_VERSION | awk '{print $2}'
      return
    fi
  fi

  # Fallback: first line of ldd --version.
  local line ver pkg
  line="$(ldd --version 2>/dev/null | head -n1 || true)"
  # last field is the upstream version ("2.39")
  ver="$(awk '{print $NF}' <<<"$line")"
  # content inside parentheses is the distro package release ("Ubuntu GLIBC 2.39-0ubuntu8.6")
  pkg="$(sed -n 's/.*(\(.*\)).*/\1/p' <<<"$line")"

  if [[ -n "$pkg" ]]; then
    printf '%s (%s)\n' "$ver" "$pkg"
  else
    printf '%s\n' "$ver"
  fi
}

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
source "${SCRIPT_DIR}/_utils.sh"

log INFO "Now executing $(basename "${0}")"

UPDATE_ALLOW_REBOOT="${UPDATE_ALLOW_REBOOT:-true}"
PKG_TIMEOUT="${PKG_TIMEOUT:-600}"
CUSTOM_PKG_FLAGS="${CUSTOM_PKG_FLAGS:-}"

check_commands_installed uname ldd sudo || { log ERROR "❌ Missing required commands."; exit 1; }

log INFO "🔄 Updating system packages"

current_kernel="$(uname -r)"
current_glibc="$(glibc_info)"

log INFO "Current kernel: $current_kernel"
log INFO "Current glibc:  $current_glibc"

if distro=$(detect_linux_distro); then
  log INFO "✅ Detected distro: $distro"
else
  log ERROR "❌ Failed to detect Linux distribution"; exit 1
fi

PKG_MGR_BIN="${SCRIPT_DIR}/package-mgr"
[[ -x "$PKG_MGR_BIN" ]] || { log ERROR "❌ '${PKG_MGR_BIN}' not found or not executable."; exit 1; }

PM_CMD=( sudo -E "$PKG_MGR_BIN" --system-update --timeout "$PKG_TIMEOUT" --auto-confirm )
[[ -n "$CUSTOM_PKG_FLAGS" ]] && PM_CMD+=( --custom-flags "$CUSTOM_PKG_FLAGS" )

"${PM_CMD[@]}"

log INFO "✅ System packages update complete!"

new_kernel="$(uname -r)"
new_glibc="$(glibc_info)"

log INFO "New kernel (after update): $new_kernel"
log INFO "New glibc (after update):  $new_glibc"

reboot_required=false
[[ "$current_kernel" != "$new_kernel" ]] && { log INFO "Kernel updated (versions changed), current: ${current_kernel} v.s. new: ${new_kernel}"; reboot_required=true; }
[[ "$current_glibc" != "$new_glibc"   ]] && { log INFO "glibc updated (versions changed), current: ${current_glibc} v.s. new: ${new_glibc}";  reboot_required=true; }

if $reboot_required; then
  if [[ "$UPDATE_ALLOW_REBOOT" == "1" || "$UPDATE_ALLOW_REBOOT" == "true" ]]; then
    log INFO "🚀✨ Rebooting system in 20s (CTRL+C to abort)"
    sleep 20
    sudo reboot
  else
    log INFO "Reboot required but skipped (set UPDATE_ALLOW_REBOOT=1 to allow)."
  fi
else
  log INFO "🎉 No reboot required."
fi

log INFO "✅ Successfully updated system packages"
exit 0

