#!/usr/bin/env bash
set -Eeuo pipefail
trap 'rc=$?; echo -e "\e[31m[TEST-ERROR]\e[0m $0:$LINENO: \"$BASH_COMMAND\" exited with $rc" >&2' ERR

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
ROOT_DIR="$(cd "${SCRIPT_DIR}/.." && pwd)"
export TEST_FAIL_FAST=1
source "${ROOT_DIR}/_utils.sh"

success "Now executing $(basename "$0")"
export PATH="$HOME/bin:$PATH"

# name|extract-dir|binary-path-relative-to-extract
entries=(
  "keychain|keychain-2.8.5|keychain"
  "geckodriver|geckodriver-v0.34.0|geckodriver"
  "hurl|hurl-4.2.0|hurl"
  "git-trim|git-trim-v0.4.3|git-trim"
  "starship|starship-v1.17.1|starship"
  "mcfly|mcfly-v0.8.4|mcfly"
)

for e in "${entries[@]}"; do
  IFS='|' read -r name extract rel <<<"$e"
  link="$HOME/bin/$name"
  dest="$HOME/bin/${name}-versions/${extract}/${rel}"

  [[ -L "$link" ]] || fail "$name symlink missing: $link"
  [[ -f "$dest" ]] || fail "$name target missing: $dest"
  [[ -x "$dest" ]] || fail "$name target not executable: $dest"
  success "$name installed: $link → $dest"
done

# sanity: --version runs for a subset
for b in geckodriver hurl starship git-trim; do
  command -v "$b" >/dev/null 2>&1 || fail "$b not on PATH"
  "$b" --version >/dev/null 2>&1 || fail "$b --version failed"
  success "$b --version runs"
done

success "install_from_http: all checks passed"

