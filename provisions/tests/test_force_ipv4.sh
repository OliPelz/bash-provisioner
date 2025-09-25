#!/usr/bin/env bash
# shUnit2 suite: force_ipv4 post-checks (does NOT run the provisioner; only verifies results)
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

# Helper: quick probes for PM families
_has_apt() { command -v apt-get >/dev/null 2>&1 || command -v apt >/dev/null 2>&1; }
_has_dnf() { command -v dnf >/dev/null 2>&1; }
_has_pacman() { command -v pacman >/dev/null 2>&1 || [[ -f /etc/pacman.conf ]]; }

test_sysctl_runtime_flags_are_set() {
    echo "Running TEST: test_sysctl_runtime_flags_are_set"
    log_test "Checking sysctl runtime flag net.ipv6.conf.all.disable_ipv6..."
    local all_val
    all_val="$(sysctl -n net.ipv6.conf.all.disable_ipv6 2>/dev/null || echo "")"
    log_test "Result: net.ipv6.conf.all.disable_ipv6: '$all_val'"
    assertNotNull "sysctl value for all.disable_ipv6 not readable" "$all_val"
    assertEquals "IPv6 runtime: all should be disabled" "1" "$all_val"
    log_test "Checking sysctl runtime flag net.ipv6.conf.default.disable_ipv6..."
    local def_val
    def_val="$(sysctl -n net.ipv6.conf.default.disable_ipv6 2>/dev/null || echo "")"
    log_test "Result: net.ipv6.conf.default.disable_ipv6: '$def_val'"
    assertNotNull "sysctl value for default.disable_ipv6 not readable" "$def_val"
    assertEquals "IPv6 runtime: default should be disabled" "1" "$def_val"
}

test_sysctl_persistent_file_written() {
    echo "Running TEST: test_sysctl_persistent_file_written"
    local f="/etc/sysctl.d/99-disable-ipv6.conf"
    log_test "Checking if sysctl persistent file exists: $f..."
    assertTrue "Persistent sysctl file missing: $f" "[ -f \"$f\" ]"
    local contents
    contents="$(cat "$f" 2>/dev/null || true)"
    log_test "Checking sysctl file content for all.disable_ipv6=1..."
    assertContains "sysctl file should set all.disable_ipv6=1" "$contents" "net.ipv6.conf.all.disable_ipv6=1"
    log_test "Result: all.disable_ipv6=1 $(echo "$contents" | grep -q "net.ipv6.conf.all.disable_ipv6=1" && echo 'found' || echo 'not found')"
    log_test "Checking sysctl file content for default.disable_ipv6=1..."
    assertContains "sysctl file should set default.disable_ipv6=1" "$contents" "net.ipv6.conf.default.disable_ipv6=1"
    log_test "Result: default.disable_ipv6=1 $(echo "$contents" | grep -q "net.ipv6.conf.default.disable_ipv6=1" && echo 'found' || echo 'not found')"
}

test_apt_ipv4_config_written_when_apt_based() {
    echo "Running TEST: test_apt_ipv4_config_written_when_apt_based"
    if ! _has_apt; then
        log_test "Not an APT-based system; skipping test"
        startSkipping
        assertTrue "Skipped: Not an APT-based system" "[ 1 -eq 1 ]"
        return 0
    fi
    local f="/etc/apt/apt.conf.d/99force-ipv4"
    log_test "Checking if APT IPv4 config file exists: $f..."
    assertTrue "APT IPv4 config file missing: $f" "[ -f \"$f\" ]"
    local c
    c="$(cat "$f" 2>/dev/null || true)"
    log_test "Checking APT config for ForceIPv4 setting..."
    assertContains "APT config should force IPv4" "$c" 'Acquire::ForceIPv4 "true";'
    log_test "Result: ForceIPv4 setting $(echo "$c" | grep -q 'Acquire::ForceIPv4 "true";' && echo 'found' || echo 'not found')"
}

test_dnf_ipv4_config_written_when_dnf_based() {
    echo "Running TEST: test_dnf_ipv4_config_written_when_dnf_based"
    if ! _has_dnf; then
        log_test "Not a DNF-based system; skipping test"
        startSkipping
        assertTrue "Skipped: Not a DNF-based system" "[ 1 -eq 1 ]"
        return 0
    fi
    local conf="/etc/dnf/dnf.conf"
    local bak="/etc/dnf/dnf.conf.bak"
    log_test "Checking if DNF config file exists: $conf..."
    assertTrue "DNF conf missing: $conf" "[ -f \"$conf\" ]"
    log_test "Checking if DNF backup file exists: $bak..."
    assertTrue "DNF backup not created: $bak" "[ -f \"$bak\" ]"
    local c
    c="$(cat "$conf" 2>/dev/null || true)"
    log_test "Checking DNF config for ip_resolve=4..."
    assertContains "DNF config should set ip_resolve=4" "$c" "ip_resolve=4"
    log_test "Result: ip_resolve=4 $(echo "$c" | grep -q "ip_resolve=4" && echo 'found' || echo 'not found')"
}

test_pacman_xfercommand_ipv4_when_arch_based() {
    echo "Running TEST: test_pacman_xfercommand_ipv4_when_arch_based"
    if ! _has_pacman; then
        log_test "Not an Arch-based system; skipping test"
        startSkipping
        assertTrue "Skipped: Not an Arch-based system" "[ 1 -eq 1 ]"
        return 0
    fi
    local conf="/etc/pacman.conf"
    local bak="/etc/pacman.conf.bak"
    log_test "Checking if pacman config file exists: $conf..."
    assertTrue "pacman.conf missing: $conf" "[ -f \"$conf\" ]"
    log_test "Checking if pacman backup file exists: $bak..."
    assertTrue "pacman backup not created: $bak" "[ -f \"$bak\" ]"
    local c
    c="$(cat "$conf" 2>/dev/null || true)"
    log_test "Checking pacman config for curl XferCommand..."
    assertContains "pacman conf should mention curl XferCommand" "$c" "XferCommand = /usr/bin/curl"
    log_test "Result: curl XferCommand $(echo "$c" | grep -q "XferCommand = /usr/bin/curl" && echo 'found' || echo 'not found')"
    log_test "Checking pacman config for --ipv4 in XferCommand..."
    assertContains "pacman curl XferCommand should enforce IPv4" "$c" "--ipv4"
    log_test "Result: --ipv4 in XferCommand $(echo "$c" | grep -q "--ipv4" && echo 'found' || echo 'not found')"
}

# Load shUnit2
. "$(command -v shunit2)"
