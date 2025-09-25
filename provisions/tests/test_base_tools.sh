#!/usr/bin/env bash
# shUnit2 suite: base tools
set -u

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
ROOT_DIR="$(cd "${SCRIPT_DIR}/.." && pwd)"

# Require shunit2 in PATH
command -v shunit2 >/dev/null 2>&1 || { echo "shunit2 not found in PATH" >&2; exit 1; }

export PATH="$HOME/bin:$PATH"
YQ_VERSION="${YQ_VERSION:-4.45.1}"

has_bin() {
  local b="$1"
  command -v "$b" >/dev/null 2>&1 && return 0
  for p in /usr/sbin /sbin /usr/local/sbin; do
    [[ -x "$p/$b" ]] && return 0
  done
  return 1
}

test_yq_symlink_and_version() {
  assertTrue "yq symlink should exist at \$HOME/bin/yq" "[ -L \"$HOME/bin/yq\" ]"
  local target
  target="$(readlink -f "$HOME/bin/yq" || true)"
  assertNotNull "yq symlink target must not be empty" "$target"
  assertTrue "yq symlink target missing: ${target:-<none>}" "[ -f \"$target\" ]"
  assertTrue "yq target not executable: $target" "[ -x \"$target\" ]"

  local installed_raw installed
  installed_raw="$("$HOME/bin/yq" --version 2>/dev/null || true)"
  installed="$(printf '%s' "$installed_raw" | sed -E 's/.*v?([0-9]+\.[0-9]+\.[0-9]+).*/\1/')"
  assertEquals "yq version should match" "$YQ_VERSION" "$installed"
}

test_base_binaries_present() {
  for b in htop xclip tmux jq curl; do
    assertTrue "binary missing: $b" "command -v $b >/dev/null 2>&1"
  done
}

test_net_tools_present() {
  local cond='command -v ifconfig >/dev/null 2>&1 || command -v netstat >/dev/null 2>&1'
  assertTrue "net-tools not found (ifconfig/netstat)" "$cond"
}

test_pkg_mgr_conf_nonfatal_info() {
  if command -v dpkg >/dev/null 2>&1; then
    for p in htop net-tools xclip tmux jq curl; do
      dpkg -s "$p" >/dev/null 2>&1 && echo "[INFO] dpkg shows installed: $p" || true
    done
  elif command -v pacman >/dev/null 2>&1; then
    for p in htop net-tools xclip tmux jq curl; do
      pacman -Q "$p" >/dev/null 2>&1 && echo "[INFO] pacman shows installed: $p" || true
    done
  elif command -v rpm >/dev/null 2>&1; then
    for p in htop net-tools xclip tmux jq curl; do
      rpm -q "$p" >/dev/null 2>&1 && echo "[INFO] rpm shows installed: $p" || true
    done
  fi
}

. "$(command -v shunit2)"
