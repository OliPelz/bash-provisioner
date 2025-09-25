#!/usr/bin/env bash
# shUnit2 suite: neovim
set -u

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
ROOT_DIR="$(cd "${SCRIPT_DIR}/.." && pwd)"

command -v shunit2 >/dev/null 2>&1 || { echo "shunit2 not found in PATH" >&2; exit 1; }

export PATH="$HOME/bin:$PATH"
NEOVIM_VERSION="${NEOVIM_VERSION:-0.10.2}"

test_neovim_symlink_and_version() {
  assertTrue "Neovim symlink missing at \$HOME/bin/neovim" "[ -L \"$HOME/bin/neovim\" ]"
  local tgt reported_raw reported_norm
  tgt="$(readlink -f "$HOME/bin/neovim" || true)"
  assertNotNull "Neovim symlink target is empty" "$tgt"
  assertTrue "Neovim link target not executable: ${tgt:-<none>}" "[ -x \"$tgt\" ]"

  reported_raw="$("$HOME/bin/neovim" --version | awk 'NR==1{print $2}')"
  reported_norm="$(printf '%s' "$reported_raw" | sed -E 's/^v//')"
  assertEquals "Neovim version should match" "$NEOVIM_VERSION" "$reported_norm"
}

. "$(command -v shunit2)"

