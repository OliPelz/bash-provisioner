#!/bin/bash
set -euo pipefail
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
ROOT_DIR="$(cd "${SCRIPT_DIR}/.." && pwd)"
source "${ROOT_DIR}/_utils.sh"
log INFO "Now executing $(basename "${0}")"

rc=0
PASS(){ log INFO "✅ $*"; }
FAIL(){ log ERROR "❌ $*"; rc=1; }

# This test verifies the *result* of an update-only provisioning:
# - No pending updates according to the host's package manager.

if command -v apt >/dev/null 2>&1; then
  # Prefer a method that doesn’t change state and doesn’t need root.
  upgradable="$(apt list --upgradable 2>/dev/null | awk 'NR>1')"
  if [[ -z "$upgradable" ]]; then
    PASS "APT reports no pending upgrades"
  else
    FAIL "APT shows pending upgrades"
    echo "$upgradable" | sed 's/^/   - /' >&2
  fi

elif command -v pacman >/dev/null 2>&1; then
  if ! pacman -Qu 2>/dev/null | grep -q .; then
    PASS "pacman reports no pending upgrades"
  else
    FAIL "pacman shows pending upgrades"
    pacman -Qu 2>/dev/null | sed 's/^/   - /' >&2 || true
  fi

elif command -v dnf >/dev/null 2>&1; then
  # dnf check-update: 0=none, 100=updates available
  if dnf -q check-update >/dev/null 2>&1; then
    PASS "DNF reports no pending upgrades"
  else
    code=$?
    if [ "$code" -eq 100 ]; then
      FAIL "DNF shows pending upgrades"
      dnf -q check-update || true
    else
      FAIL "DNF check-update returned error code $code"
    fi
  fi

else
  FAIL "Unsupported or unknown package manager; cannot verify update state"
fi

if [ "$rc" -eq 0 ]; then PASS "update_system_packages: host is fully updated"; else FAIL "update_system_packages: updates pending or check failed"; fi
exit "$rc"
