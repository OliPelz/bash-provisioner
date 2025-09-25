#!/usr/bin/env bash
# shUnit2 suite: prepare_bash_shell
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

test_bashrc_block_and_source_line() {
    echo "Running TEST: test_bashrc_block_and_source_line"
    log_test "Checking if ~/.bashrc exists..."
    assertTrue "~/.bashrc not found" "[ -f \"${HOME}/.bashrc\" ]"
    local start_count end_count needle bashrc_contents
    log_test "Checking BASHRC-CONFIG start marker count..."
    start_count="$(grep -c '^# BASHRC-CONFIG' "${HOME}/.bashrc" || true)"
    log_test "Result: BASHRC-CONFIG start marker count: $start_count"
    assertEquals "BASHRC-CONFIG start marker count should be 1" "1" "$start_count"
    log_test "Checking BASHRC-CONFIG end marker count..."
    end_count="$(grep -c '^# /BASHRC-CONFIG' "${HOME}/.bashrc" || true)"
    log_test "Result: BASHRC-CONFIG end marker count: $end_count"
    assertEquals "BASHRC-CONFIG end marker count should be 1" "1" "$end_count"
    needle='test -f ${HOME}/.bashrc-config && source ${HOME}/.bashrc-config'
    bashrc_contents="$(cat "${HOME}/.bashrc")"
    log_test "Checking if ~/.bashrc sources ~/.bashrc-config..."
    assertContains "~/.bashrc should source ~/.bashrc-config" "$bashrc_contents" "$needle"
    log_test "Result: ~/.bashrc-config source line $(echo "$bashrc_contents" | grep -q "$needle" && echo 'found' || echo 'not found')"
}

# Load shUnit2
. "$(command -v shunit2)"
