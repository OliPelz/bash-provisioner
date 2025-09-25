#!/usr/bin/env bash
# shUnit2 suite: base tools
set -u
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
ROOT_DIR="$(cd "${SCRIPT_DIR}/.." && pwd)"
# Require shunit2 in PATH
command -v shunit2 >/dev/null 2>&1 || { echo "shunit2 not found in PATH" >&2; exit 1; }
export PATH="$HOME/bin:$PATH"
YQ_VERSION="${YQ_VERSION:-4.45.1}"
# Set test prefix for verbose output
SHUNIT_TEST_PREFIX='TEST: '

# Helper function for verbose logging
log_test() {
    echo "  $1"
}

has_bin() {
    local b="$1"
    command -v "$b" >/dev/null 2>&1 && return 0
    for p in /usr/sbin /sbin /usr/local/sbin; do
        [[ -x "$p/$b" ]] && return 0
    done
    return 1
}

test_yq_symlink_and_version() {
    echo "Running TEST: test_yq_symlink_and_version"
    log_test "Checking if yq symlink exists at \$HOME/bin/yq..."
    assertTrue "yq symlink should exist at \$HOME/bin/yq" "[ -L \"$HOME/bin/yq\" ]"
    local target
    target="$(readlink -f "$HOME/bin/yq" || true)"
    log_test "Result: yq symlink target: '${target:-<none>}'"
    assertNotNull "yq symlink target must not be empty" "$target"
    assertTrue "yq symlink target missing: ${target:-<none>}" "[ -f \"$target\" ]"
    assertTrue "yq target not executable: $target" "[ -x \"$target\" ]"
    local installed_raw installed
    log_test "Checking yq version..."
    installed_raw="$("$HOME/bin/yq" --version 2>/dev/null || true)"
    installed="$(printf '%s' "$installed_raw" | sed -E 's/.*v?([0-9]+\.[0-9]+\.[0-9]+).*/\1/')"
    log_test "Result: yq version: '$installed' (expected: $YQ_VERSION)"
    assertEquals "yq version should match" "$YQ_VERSION" "$installed"
}

test_base_binaries_present() {
    echo "Running TEST: test_base_binaries_present"
    for b in htop xclip tmux jq curl; do
        log_test "Checking if binary $b is present..."
        assertTrue "binary missing: $b" "command -v $b >/dev/null 2>&1"
        log_test "Result: binary $b $(command -v $b >/dev/null 2>&1 && echo 'found' || echo 'not found')"
    done
}

test_net_tools_present() {
    echo "Running TEST: test_net_tools_present"
    log_test "Checking for net-tools (ifconfig or netstat)..."
    local cond='command -v ifconfig >/dev/null 2>&1 || command -v netstat >/dev/null 2>&1'
    assertTrue "net-tools not found (ifconfig/netstat)" "$cond"
    log_test "Result: net-tools $(eval $cond && echo 'found' || echo 'not found')"
}

test_pkg_mgr_conf_nonfatal_info() {
    echo "Running TEST: test_pkg_mgr_conf_nonfatal_info"
    if command -v dpkg >/dev/null 2>&1; then
        log_test "Checking dpkg package status..."
        for p in htop net-tools xclip tmux jq curl; do
            log_test "Checking package $p..."
            dpkg -s "$p" >/dev/null 2>&1 && echo "[INFO] dpkg shows installed: $p" || true
            log_test "Result: package $p $(dpkg -s "$p" >/dev/null 2>&1 && echo 'installed' || echo 'not installed')"
        done
    elif command -v pacman >/dev/null 2>&1; then
        log_test "Checking pacman package status..."
        for p in htop net-tools xclip tmux jq curl; do
            log_test "Checking package $p..."
            pacman -Q "$p" >/dev/null 2>&1 && echo "[INFO] pacman shows installed: $p" || true
            log_test "Result: package $p $(pacman -Q "$p" >/dev/null 2>&1 && echo 'installed' || echo 'not installed')"
        done
    elif command -v rpm >/dev/null 2>&1; then
        log_test "Checking rpm package status..."
        for p in htop net-tools xclip tmux jq curl; do
            log_test "Checking package $p..."
            rpm -q "$p" >/dev/null 2>&1 && echo "[INFO] rpm shows installed: $p" || true
            log_test "Result: package $p $(rpm -q "$p" >/dev/null 2>&1 && echo 'installed' || echo 'not installed')"
        done
    else
        log_test "No supported package manager found (dpkg, pacman, rpm)"
    fi
}

# Load shUnit2
. "$(command -v shunit2)"
