#!/usr/bin/env bash
set -Eeuo pipefail

# --- Source utils (for log if you want; optional) ---
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
source "${SCRIPT_DIR}/_utils.sh"

log INFO "Now executing $(basename "${0}")"

# Early exit if IPv6 is not explicitly disabled
if [[ "${DISABLE_IPV6:-}" != "true" && "${DISABLE_IPV6:-}" != "1" ]]; then
  log INFO "IPv6 remains enabled (set DISABLE_IPV6=true to force IPv4)."
  exit 0
fi

# We use: sudo, cp, tee, sysctl, grep, awk
check_commands_installed sudo cp tee sysctl grep awk || { log ERROR "❌ Missing required commands."; exit 1; }

log INFO "Forcing IPv4 across package managers and networking..."

if distro=$(detect_linux_distro); then
  log INFO "✅ Detected distro: $distro"
else
  log ERROR "❌ Failed to detect Linux distribution"
  exit 1
fi

case "$distro" in
  debian|ubuntu)
    sudo tee /etc/apt/apt.conf.d/99force-ipv4 >/dev/null <<'EOF'
Acquire::ForceIPv4 "true";
EOF
    log INFO "Configured APT to prefer IPv4."
    ;;

  arch)
    [[ -f /etc/pacman.conf.bak ]] || sudo cp /etc/pacman.conf /etc/pacman.conf.bak
    # If XferCommand is not present, append a curl-based one that forces IPv4
    if ! grep -Eq '^[[:space:]]*XferCommand[[:space:]]*=' /etc/pacman.conf; then
      sudo tee -a /etc/pacman.conf >/dev/null <<'EOF'

# Force IPv4 downloads
XferCommand = /usr/bin/curl -L -C - --ipv4 --retry 3 --retry-delay 3 -o %o %u
EOF
      log INFO "Configured pacman XferCommand to curl --ipv4."
    else
      log INFO "pacman XferCommand already set; ensure it includes --ipv4 if needed."
    fi
    ;;

  rhel|centos|rocky|almalinux|fedora)
    sudo cp /etc/dnf/dnf.conf /etc/dnf/dnf.conf.bak 2>/dev/null || true
    sudo awk '
      BEGIN{done=0}
      /^\[main\]/{print; print "ip_resolve=4"; done=1; next}
      {print}
      END{if(!done) print "[main]\nip_resolve=4"}' /etc/dnf/dnf.conf | sudo tee /etc/dnf/dnf.conf >/dev/null
    log INFO "Configured DNF to use IPv4."
    ;;

  *)
    log ERROR "❌ Unsupported distro: $distro"
    exit 1
    ;;
esac

# ---- System-wide: disable IPv6 (runtime + persistent)
sudo sysctl -w net.ipv6.conf.all.disable_ipv6=1 >/dev/null || true
sudo sysctl -w net.ipv6.conf.default.disable_ipv6=1 >/dev/null || true

sudo tee /etc/sysctl.d/99-disable-ipv6.conf >/dev/null <<'EOF'
net.ipv6.conf.all.disable_ipv6=1
net.ipv6.conf.default.disable_ipv6=1
EOF

log INFO "IPv6 disabled via sysctl (persisted). A reboot may be required for all services."
log INFO "✅ Successfully forced IPv4 settings"
exit 0

