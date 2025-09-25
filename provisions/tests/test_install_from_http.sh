#!/usr/bin/env bash
# shUnit2 suite: install_from_http
set -u
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
ROOT_DIR="$(cd "${SCRIPT_DIR}/.." && pwd)"
command -v shunit2 >/dev/null 2>&1 || { echo "shunit2 not found in PATH" >&2; exit 1; }
export PATH="$HOME/bin:$PATH"
# Set test prefix for verbose output
SHUNIT_TEST_PREFIX='TEST: '

# Helper function for verbose logging
log_test() {
    echo "  $1"
}

test_installed_binaries_and_symlinks() {
    echo "Running TEST: test_installed_binaries_and_symlinks"
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
        log_test "Checking $name symlink: $link..."
        assertTrue "$name symlink missing: $link" "[ -L \"$link\" ]"
        log_test "Result: $name symlink $([ -L "$link" ] && echo 'found' || echo 'not found')"
        log_test "Checking $name target: $dest..."
        assertTrue "$name target missing: $dest" "[ -f \"$dest\" ]"
        log_test "Result: $name target $([ -f "$dest" ] && echo 'found' || echo 'not found')"
        log_test "Checking if $name target is executable: $dest..."
        assertTrue "$name target not executable: $dest" "[ -x \"$dest\" ]"
        log_test "Result: $name target executable $([ -x "$dest" ] && echo 'yes' || echo 'no')"
    done
    for b in geckodriver hurl starship git-trim; do
        log_test "Checking if $b is on PATH..."
        assertTrue "$b not on PATH" "command -v $b >/dev/null 2>&1"
        log_test "Result: $b on PATH $(command -v $b >/dev/null 2>&1 && echo 'yes' || echo 'no')"
        log_test "Checking if $b --version runs..."
        assertTrue "$b --version failed" "$b --version >/dev/null 2>&1"
        log_test "Result: $b --version $( $b --version >/dev/null 2>&1 && echo 'succeeded' || echo 'failed')"
    done
}

# Load shUnit2
. "$(command -v shunit2)"
