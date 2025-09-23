# force_ipv4.sh
#!/usr/bin/env bash
set -Eeuo pipefail

# --- Source utils (for log if you want; optional) ---
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
if [[ -f "${SCRIPT_DIR}/_utils.sh" ]]; then source "${SCRIPT_DIR}/_utils.sh"; else log(){ echo "$@"; }; fi

if [[ "${DISABLE_IPV6:-}" != "true" && "${DISABLE_IPV6:-}" != "1" ]]; then
  log INFO "IPv6 remains enabled (set DISABLE_IPV6=true to force IPv4)."
  exit 0
fi

log INFO "Forcing IPv4 across package managers and networking..."

# ---- APT: Force IPv4
if command -v apt-get >/dev/null 2>&1; then
  sudo tee /etc/apt/apt.conf.d/99force-ipv4 >/dev/null <<'EOF'
Acquire::ForceIPv4 "true";
EOF
  log INFO "Configured APT to prefer IPv4."
fi

# ---- DNF: Force IPv4
if command -v dnf >/dev/null 2>&1; then
  sudo cp /etc/dnf/dnf.conf /etc/dnf/dnf.conf.bak 2>/dev/null || true
  sudo awk '
    BEGIN{done=0}
    /^\[main\]/{print; print "ip_resolve=4"; done=1; next}
    {print}
    END{if(!done) print "[main]\nip_resolve=4"}' /etc/dnf/dnf.conf | sudo tee /etc/dnf/dnf.conf >/dev/null
  log INFO "Configured DNF to use IPv4."
fi

# ---- pacman: Force IPv4 via XferCommand (curl) if not already set
if command -v pacman >/dev/null 2>&1; then
  # Backup once
  [[ -f /etc/pacman.conf.bak ]] || sudo cp /etc/pacman.conf /etc/pacman.conf.bak
  if ! grep -q '^\s*XferCommand\s*=' /etc/pacman.conf; then
    sudo tee -a /etc/pacman.conf >/dev/null <<'EOF'

# Force IPv4 downloads
XferCommand = /usr/bin/curl -L -C - --ipv4 --retry 3 --retry-delay 3 -o %o %u
EOF
    log INFO "Configured pacman XferCommand to curl --ipv4."
  else
    log INFO "pacman XferCommand already set; ensure it includes --ipv4 if needed."
  fi
fi

# ---- System-wide: disable IPv6 (runtime + persistent)
# Runtime (non-breaking if already disabled)
sudo sysctl -w net.ipv6.conf.all.disable_ipv6=1 >/dev/null || true
sudo sysctl -w net.ipv6.conf.default.disable_ipv6=1 >/dev/null || true

# Persistent
sudo tee /etc/sysctl.d/99-disable-ipv6.conf >/dev/null <<'EOF'
net.ipv6.conf.all.disable_ipv6=1
net.ipv6.conf.default.disable_ipv6=1
EOF

log INFO "IPv6 disabled via sysctl (persisted). A reboot may be required for all services."

