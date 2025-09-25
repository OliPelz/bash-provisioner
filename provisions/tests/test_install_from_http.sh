#!/usr/bin/env bash
# shUnit2 suite: install_from_http
set -u

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
ROOT_DIR="$(cd "${SCRIPT_DIR}/.." && pwd)"

command -v shunit2 >/dev/null 2>&1 || { echo "shunit2 not found in PATH" >&2; exit 1; }

export PATH="$HOME/bin:$PATH"

test_installed_binaries_and_symlinks() {
  local entries=(
    "keychain|keychain-2.8.5|keychain"
    "geckodriver|geckodriver-v0.34.0|geckodriver"
    "hurl|hurl-4.2.0|hurl"
    "git-trim|git-trim-v0.4.3|git-trim"
    "starship|starship-v1.17.1|starship"
    "mcfly|mcfly-v0.8.4|mcfly"
  )
  local e name extract rel link dest
  for e in "${entries[@]}"; do
    IFS='|' read -r name extract rel <<<"$e"
    link="$HOME/bin/$name"
    dest="$HOME/bin/${name}-versions/${extract}/${rel}"
    assertTrue "$name symlink missing: $link" "[ -L \"$link\" ]"
    assertTrue "$name target missing: $dest"  "[ -f \"$dest\" ]"
    assertTrue "$name target not executable: $dest" "[ -x \"$dest\" ]"
  done

  # sanity checks: versions run
  for b in geckodriver hurl starship git-trim; do
    assertTrue "$b not on PATH" "command -v $b >/dev/null 2>&1"
    assertTrue "$b --version failed" "$b --version >/dev/null 2>&1"
  done
}

. "$(command -v shunit2)"

