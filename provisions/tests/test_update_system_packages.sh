#!/usr/bin/env bash
set -Eeuo pipefail
trap 'rc=$?; echo -e "\e[31m[TEST-ERROR]\e[0m $0:$LINENO: \"$BASH_COMMAND\" exited with $rc" >&2' ERR

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
ROOT_DIR="$(cd "${SCRIPT_DIR}/.." && pwd)"
export TEST_FAIL_FAST=1
source "${ROOT_DIR}/_utils.sh"

success "Now executing $(basename "$0")"

if command -v apt >/dev/null 2>&1; then
  upgradable="$(apt list --upgradable 2>/dev/null | awk 'NR>1')"
  [[ -z "$upgradable" ]] || { printf '%s\n' "$upgradable" >&2; fail "APT shows pending upgrades"; }
  success "APT reports no pending upgrades"

elif command -v pacman >/dev/null 2>&1; then
  if pacman -Qu 2>/dev/null | grep -q .; then
    pacman -Qu 2>/dev/null | sed 's/^/   - /' >&2 || true
    fail "pacman shows pending upgrades"
  fi
  success "pacman reports no pending upgrades"

elif command -v dnf >/dev/null 2>&1; then
  if dnf -q check-update >/dev/null 2>&1; then
    success "DNF reports no pending upgrades"
  else
    code=$?
    if [[ "$code" -eq 100 ]]; then
      dnf -q check-update || true
      fail "DNF shows pending upgrades"
    else
      fail "DNF check-update returned error code $code"
    fi
  fi

else
  fail "Unsupported or unknown package manager; cannot verify update state"
fi

success "update_system_packages: host is fully updated"

