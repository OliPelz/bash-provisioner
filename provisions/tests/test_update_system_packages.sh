#!/usr/bin/env bash
# shUnit2 suite: update_system_packages
set -u
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
ROOT_DIR="$(cd "${SCRIPT_DIR}/.." && pwd)"
command -v shunit2 >/dev/null 2>&1 || { echo "shunit2 not found in PATH" >&2; exit 1; }
# Set test prefix for verbose output
SHUNIT_TEST_PREFIX='TEST: '

# Helper function for verbose logging
log_test() {
    echo "  $1"
}

test_no_pending_updates() {
    echo "Running TEST: test_no_pending_updates"
    if command -v apt >/dev/null 2>&1; then
        log_test "Checking for pending APT updates..."
        local upgradable
        upgradable="$(apt list --upgradable 2>/dev/null | awk 'NR>1')"
        [[ -n "$upgradable" ]] && printf '%s\n' "$upgradable" >&2
        log_test "Result: APT upgradable packages: '$upgradable'"
        assertTrue "APT shows pending upgrades" "[[ -z \"$upgradable\" ]]"
    elif command -v pacman >/dev/null 2>&1; then
        log_test "Checking for pending pacman updates..."
        local pacman_output
        pacman_output=$(pacman -Qu 2>/dev/null)
        if echo "$pacman_output" | grep -q .; then
            echo "$pacman_output" | sed 's/^/ - /' >&2
        fi
        log_test "Result: pacman pending updates: $(if [[ -n "$pacman_output" ]]; then echo 'found'; else echo 'none'; fi)"
        assertFalse "pacman shows pending upgrades" "pacman -Qu 2>/dev/null | grep -q ."
    elif command -v dnf >/dev/null 2>&1; then
        log_test "Checking for pending DNF updates..."
        dnf -q check-update >/dev/null 2>&1
        local code=$?
        if [[ "$code" -ne 0 ]]; then
            [[ "$code" -eq 100 ]] && dnf -q check-update >&2 || true
        fi
        log_test "Result: DNF check-update return code: $code"
        assertTrue "DNF shows pending upgrades (rc=$code)" "[[ $code -eq 0 ]]"
    else
        log_test "No supported package manager found"
        fail "Unsupported or unknown package manager; cannot verify update state"
    fi
}

# Load shUnit2
. "$(command -v shunit2)"
