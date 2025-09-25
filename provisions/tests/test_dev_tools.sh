#!/usr/bin/env bash
# shUnit2 suite: dev tools
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

test_dev_toolchain_binaries() {
    echo "Running TEST: test_dev_toolchain_binaries"
    for b in gcc make; do
        log_test "Checking if binary $b is present..."
        assertTrue "binary missing: $b" "command -v $b >/dev/null 2>&1"
        log_test "Result: binary $b $(command -v $b >/dev/null 2>&1 && echo 'found' || echo 'not found')"
    done
}

# Load shUnit2
. "$(command -v shunit2)"
