#!/bin/bash
set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
ROOT_DIR="$(cd "${SCRIPT_DIR}/.." && pwd)"
source "${ROOT_DIR}/_utils.sh"

log INFO "Now executing $(basename "${0}")"

rc=0
PASS(){ log INFO "✅ $*"; }
FAIL(){ log ERROR "❌ $*"; rc=1; }

# Respect the version the host was provisioned with (or default)
YQ_VERSION="${YQ_VERSION:-4.45.1}"
export PATH="$HOME/bin:$PATH"

# --- yq: symlink exists, target exists & executable, and version matches ---
if [ -L "$HOME/bin/yq" ]; then
  target="$(readlink -f "$HOME/bin/yq" || true)"
  if [[ -n "${target:-}" && -f "$target" && -x "$target" ]]; then
    # yq --version prints "... version 4.45.1"
    installed="$("$HOME/bin/yq" --version 2>/dev/null | awk '{for(i=1;i<=NF;i++) if($i=="version") {print $(i+1); exit}}')"
    if [[ "$installed" == "$YQ_VERSION" ]]; then
      PASS "yq present via symlink and version is $installed"
    else
      FAIL "yq version mismatch: expected $YQ_VERSION, got ${installed:-<none>}"
    fi
  else
    FAIL "yq symlink target missing or not executable: ${target:-<none>}"
  fi
else
  FAIL "yq symlink missing at \$HOME/bin/yq"
fi

# Helper: some tools might live in sbin
has_bin(){
  local b="$1"
  command -v "$b" >/dev/null 2>&1 && return 0
  for p in /usr/sbin /sbin /usr/local/sbin; do
    [[ -x "$p/$b" ]] && return 0
  done
  return 1
}

# Verify base tools by checking their binaries
for b in htop xclip tmux jq curl; do
  if has_bin "$b"; then
    PASS "binary available: $b"
  else
    FAIL "binary missing: $b"
  fi
done

# net-tools check (ifconfig or netstat)
if has_bin ifconfig || has_bin netstat; then
  PASS "net-tools present (ifconfig/netstat)"
else
  FAIL "net-tools not found (ifconfig/netstat)"
fi

# Optional package-manager confirmation (best-effort; non-fatal if absent)
if command -v dpkg >/dev/null 2>&1; then
  for p in htop net-tools xclip tmux jq curl; do
    if dpkg -s "$p" >/dev/null 2>&1; then PASS "dpkg shows installed: $p"; fi
  done
elif command -v pacman >/dev/null 2>&1; then
  for p in htop net-tools xclip tmux jq curl; do
    if pacman -Q "$p" >/dev/null 2>&1; then PASS "pacman shows installed: $p"; fi
  done
elif command -v rpm >/dev/null 2>&1; then
  for p in htop net-tools xclip tmux jq curl; do
    if rpm -q "$p" >/dev/null 2>&1; then PASS "rpm shows installed: $p"; fi
  done
fi

if [ "$rc" -eq 0 ]; then PASS "base_tools: all checks passed"; else FAIL "base_tools: one or more checks failed"; fi
exit "$rc"

