#!/usr/bin/env bash
# shUnit2 suite: update_system_packages
set -u

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
ROOT_DIR="$(cd "${SCRIPT_DIR}/.." && pwd)"

command -v shunit2 >/dev/null 2>&1 || { echo "shunit2 not found in PATH" >&2; exit 1; }

test_no_pending_updates() {
  if command -v apt >/dev/null 2>&1; then
    local upgradable
    upgradable="$(apt list --upgradable 2>/dev/null | awk 'NR>1')"
    [[ -n "$upgradable" ]] && printf '%s\n' "$upgradable" >&2
    assertTrue "APT shows pending upgrades" "[[ -z \"$upgradable\" ]]"

  elif command -v pacman >/dev/null 2>&1; then
    if pacman -Qu 2>/dev/null | grep -q .; then pacman -Qu 2>/dev/null | sed 's/^/   - /' >&2 || true; fi
    assertFalse "pacman shows pending upgrades" "pacman -Qu 2>/dev/null | grep -q ."

  elif command -v dnf >/dev/null 2>&1; then
    dnf -q check-update >/dev/null 2>&1
    local code=$?
    if [[ "$code" -ne 0 ]]; then
      [[ "$code" -eq 100 ]] && dnf -q check-update || true
    fi
    assertTrue "DNF shows pending upgrades (rc=$code)" "[[ $code -eq 0 ]]"

  else
    fail "Unsupported or unknown package manager; cannot verify update state"
  fi
}

. "$(command -v shunit2)"

