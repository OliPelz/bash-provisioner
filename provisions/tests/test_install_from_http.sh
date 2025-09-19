#!/bin/bash
set -euo pipefail
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
ROOT_DIR="$(cd "${SCRIPT_DIR}/.." && pwd)"
source "${ROOT_DIR}/_utils.sh"
log INFO "Now executing $(basename "${0}")"

rc=0
PASS(){ log INFO "✅ $*"; }
FAIL(){ log ERROR "❌ $*"; rc=1; }

export PATH="$HOME/bin:$PATH"

# Verify the YAML-driven installs (from install_from_http.yaml)
entries=(
  "keychain|keychain-2.8.5|keychain"
  "geckodriver|geckodriver-v0.34.0|geckodriver"
  "hurl|hurl-4.2.0|hurl"
  "git-trim|git-trim-v0.4.3|git-trim"
  "starship|starship-v1.17.1|starship"
  "mcfly|mcfly-v0.8.4|mcfly"
)

for e in "${entries[@]}"; do
  IFS='|' read -r name extract path <<<"$e"
  link="$HOME/bin/$name"
  dest="$HOME/bin/${name}-versions/${extract}/${path}"
  if [ -L "$link" ] && [ -f "$dest" ] && [ -x "$dest" ]; then
    PASS "$name installed: $link → $dest"
  else
    FAIL "$name not properly installed (link/target/executable bit)"
  fi
done

# Light sanity: versions run for a subset (won’t modify system)
for b in geckodriver hurl starship git-trim; do
  if command -v "$b" >/dev/null 2>&1 && "$b" --version >/dev/null 2>&1; then
    PASS "$b --version runs"
  else
    FAIL "$b not usable (not on PATH or --version failed)"
  fi
done

if [ "$rc" -eq 0 ]; then PASS "install_from_http: all checks passed"; else FAIL "install_from_http: one or more checks failed"; fi
exit "$rc"
