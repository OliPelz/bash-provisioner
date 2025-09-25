#!/usr/bin/env bash
# shUnit2 suite: neovim
set -u
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
ROOT_DIR="$(cd "${SCRIPT_DIR}/.." && pwd)"
command -v shunit2 >/dev/null 2>&1 || { echo "shunit2 not found in PATH" >&2; exit 1; }
export PATH="$HOME/bin:$PATH"
NEOVIM_VERSION="${NEOVIM_VERSION:-0.10.2}"
# Set test prefix for verbose output
SHUNIT_TEST_PREFIX='TEST: '

# Helper function for verbose logging
log_test() {
    echo "  $1"
}

test_neovim_symlink_and_version() {
    echo "Running TEST: test_neovim_symlink_and_version"
    log_test "Checking if Neovim symlink exists at \$HOME/bin/neovim..."
    assertTrue "Neovim symlink missing at \$HOME/bin/neovim" "[ -L \"$HOME/bin/neovim\" ]"
    local tgt
    tgt="$(readlink -f "$HOME/bin/neovim" || true)"
    log_test "Result: Neovim symlink target: '${tgt:-<none>}'"
    assertNotNull "Neovim symlink target is empty" "$tgt"
    log_test "Checking if Neovim target is executable: ${tgt:-<none>}..."
    assertTrue "Neovim link target not executable: ${tgt:-<none>}" "[ -x \"$tgt\" ]"
    local reported_raw reported_norm
    log_test "Checking Neovim version..."
    reported_raw="$("$HOME/bin/neovim" --version | awk 'NR==1{print $2}')"
    reported_norm="$(printf '%s' "$reported_raw" | sed -E 's/^v//')"
    log_test "Result: Neovim version: '$reported_norm' (expected: $NEOVIM_VERSION)"
    assertEquals "Neovim version should match" "$NEOVIM_VERSION" "$reported_norm"
}

# Load shUnit2
. "$(command -v shunit2)"
