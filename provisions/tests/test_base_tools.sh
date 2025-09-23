#!/usr/bin/env bash
set -Eeuo pipefail
trap 'rc=$?; echo -e "\e[31m[TEST-ERROR]\e[0m $0:$LINENO: \"$BASH_COMMAND\" exited with $rc" >&2' ERR

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
ROOT_DIR="$(cd "${SCRIPT_DIR}/.." && pwd)"
export TEST_FAIL_FAST=1
source "${ROOT_DIR}/_utils.sh"

success "Now executing $(basename "$0")"

# Respect the version the host was provisioned with (or default)
YQ_VERSION="${YQ_VERSION:-4.45.1}"
export PATH="$HOME/bin:$PATH"

# helper: some tools might live in sbin
has_bin() {
  local b="$1"
  command -v "$b" >/dev/null 2>&1 && return 0
  for p in /usr/sbin /sbin /usr/local/sbin; do
    [[ -x "$p/$b" ]] && return 0
  done
  return 1
}

# --- yq symlink & version ---
if [[ -L "$HOME/bin/yq" ]]; then
  target="$(readlink -f "$HOME/bin/yq" || true)"
  [[ -n "${target:-}" ]] || fail "yq symlink target is empty"
  [[ -f "$target" ]]     || fail "yq symlink target missing: ${target:-<none>}"
  [[ -x "$target" ]]     || fail "yq symlink target not executable: $target"

  installed_raw="$("$HOME/bin/yq" --version 2>/dev/null || true)"
  installed="$(printf '%s' "$installed_raw" | sed -E 's/.*v?([0-9]+\.[0-9]+\.[0-9]+).*/\1/')"
  assert_eq "$YQ_VERSION" "$installed" "yq version should match"
  success "yq present via symlink and version is $installed"
else
  fail "yq symlink missing at \$HOME/bin/yq"
fi

# --- binaries present ---
for b in htop xclip tmux jq curl; do
  if has_bin "$b"; then
    success "binary available: $b"
  else
    fail "binary missing: $b"
  fi
done

# --- net-tools ---
if has_bin ifconfig || has_bin netstat; then
  success "net-tools present (ifconfig/netstat)"
else
  fail "net-tools not found (ifconfig/netstat)"
fi

# --- optional package manager confirmations (non-fatal info) ---
if command -v dpkg >/dev/null 2>&1; then
  for p in htop net-tools xclip tmux jq curl; do
    dpkg -s "$p" >/dev/null 2>&1 && success "dpkg shows installed: $p" || true
  done
elif command -v pacman >/dev/null 2>&1; then
  for p in htop net-tools xclip tmux jq curl; do
    pacman -Q "$p" >/dev/null 2>&1 && success "pacman shows installed: $p" || true
  done
elif command -v rpm >/dev/null 2>&1; then
  for p in htop net-tools xclip tmux jq curl; do
    rpm -q "$p" >/dev/null 2>&1 && success "rpm shows installed: $p" || true
  done
fi

success "base_tools: all checks passed"
