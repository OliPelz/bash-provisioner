#!/usr/bin/env bash
set -Eeuo pipefail
trap 'rc=$?; echo -e "\e[31m[TEST-ERROR]\e[0m $0:$LINENO: \"$BASH_COMMAND\" exited with $rc" >&2' ERR

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
ROOT_DIR="$(cd "${SCRIPT_DIR}/.." && pwd)"
export TEST_FAIL_FAST=1
source "${ROOT_DIR}/_utils.sh"

success "Now executing $(basename "$0")"

UNDER_TEST="${ROOT_DIR}/force_ipv4.sh"

# --- helpers ------------------------------------------------------------------

make_temp_env() {
  TD="$(mktemp -d)"; export TD
  ETC="${TD}/etc"; mkdir -p "${ETC}"/{apt/apt.conf.d,dnf,sysctl.d}
  BIN="${TD}/bin"; mkdir -p "${BIN}"
  export TEST_ETC="${TD}"   # our stubs map /etc -> $TEST_ETC/etc
  export PATH="${BIN}:${PATH}"
}

stub_common_tools() {
  # sudo: just run the command as-is
  cat > "${BIN}/sudo" <<'EOF'; chmod +x "${BIN}/sudo"
#!/usr/bin/env bash
exec "$@"
EOF

  # tee: map /etc/... to $TEST_ETC/etc/...; create parent dirs; honor -a
  cat > "${BIN}/tee" <<'EOF'; chmod +x "${BIN}/tee"
#!/usr/bin/env bash
set -Eeuo pipefail
map_path(){ local a="$1"; [[ "$a" == /etc/* ]] && echo "${TEST_ETC}${a}" || echo "$a"; }
args=(); targets=()
for a in "$@"; do
  case "$a" in
    -*) args+=("$a") ;;
    *)  p="$(map_path "$a")"; args+=("$p"); targets+=("$p") ;;
  esac
done
for t in "${targets[@]}"; do mkdir -p "$(dirname "$t")"; done
exec /usr/bin/tee "${args[@]}"
EOF

  # cp: map /etc paths
  cat > "${BIN}/cp" <<'EOF'; chmod +x "${BIN}/cp"
#!/usr/bin/env bash
set -Eeuo pipefail
map(){ [[ "$1" == /etc/* ]] && echo "${TEST_ETC}$1" || echo "$1"; }
last="${@: -1}"; dest="$(map "$last")"
mkdir -p "$(dirname "$dest")"
mapped=()
for a in "$@"; do mapped+=("$(map "$a")"); done
exec /bin/cp "${mapped[@]}"
EOF

  # awk: map any /etc arg to TEST_ETC and pass through
  cat > "${BIN}/awk" <<'EOF'; chmod +x "${BIN}/awk"
#!/usr/bin/env bash
set -Eeuo pipefail
mapped=()
for a in "$@"; do
  [[ "$a" == /etc/* ]] && mapped+=("${TEST_ETC}$a") || mapped+=("$a")
done
exec /usr/bin/awk "${mapped[@]}"
EOF

  # grep: map file operand(s) under /etc
  cat > "${BIN}/grep" <<'EOF'; chmod +x "${BIN}/grep"
#!/usr/bin/env bash
set -Eeuo pipefail
mapped=()
for a in "$@"; do
  [[ "$a" == /etc/* ]] && mapped+=("${TEST_ETC}$a") || mapped+=("$a")
done
exec /bin/grep "${mapped[@]}"
EOF

  # sysctl: accept -w and succeed (no real kernel change)
  cat > "${BIN}/sysctl" <<'EOF'; chmod +x "${BIN}/sysctl"
#!/usr/bin/env bash
exit 0
EOF
}

stub_manager_presence() {
  local want="${1:-}"  # "apt" | "dnf" | "pacman" | "none"
  rm -f "${BIN}/apt-get" "${BIN}/dnf" "${BIN}/pacman"
  case "$want" in
    apt)    printf '#!/usr/bin/env bash\nexit 0\n' > "${BIN}/apt-get" ;;
    dnf)    printf '#!/usr/bin/env bash\nexit 0\n' > "${BIN}/dnf" ;;
    pacman) printf '#!/usr/bin/env bash\nexit 0\n' > "${BIN}/pacman" ;;
    none|'') : ;;
  esac
  [[ -f "${BIN}/apt-get" ]] && chmod +x "${BIN}/apt-get"
  [[ -f "${BIN}/dnf"     ]] && chmod +x "${BIN}/dnf"
  [[ -f "${BIN}/pacman"  ]] && chmod +x "${BIN}/pacman"
}

run_script() {
  # pass through our fake etc via TEST_ETC for stubs
  DISABLE_IPV6="${1:-}" TEST_ETC="${TEST_ETC}" PATH="${PATH}" bash -Eeuo pipefail "${UNDER_TEST}"
}

# --- tests --------------------------------------------------------------------

# 1) Early exit when DISABLE_IPV6 is not set/true
make_temp_env
stub_common_tools
stub_manager_presence none
run_script ""   # DISABLE_IPV6 not set
# no files should be created
[[ ! -e "${ETC}/apt/apt.conf.d/99force-ipv4" ]] || fail "apt conf should not exist when IPv6 not disabled"
[[ ! -e "${ETC}/sysctl.d/99-disable-ipv6.conf" ]] || fail "sysctl conf should not exist when IPv6 not disabled"
success "early-exit leaves system untouched"
rm -rf "${TD}"

# 2) APT path: creates apt force IPv4 + sysctl file
make_temp_env
stub_common_tools
stub_manager_presence apt
run_script "true"
apt_conf="${ETC}/apt/apt.conf.d/99force-ipv4"
[[ -f "$apt_conf" ]] || fail "APT force IPv4 file missing"
assert_in 'Acquire::ForceIPv4 "true";' "$(cat "$apt_conf")" "APT config should force IPv4"

sysctl_conf="${ETC}/sysctl.d/99-disable-ipv6.conf"
[[ -f "$sysctl_conf" ]] || fail "sysctl IPv6 disable file missing"
assert_in 'net.ipv6.conf.all.disable_ipv6=1'  "$(cat "$sysctl_conf")" "sysctl all disable"
assert_in 'net.ipv6.conf.default.disable_ipv6=1' "$(cat "$sysctl_conf")" "sysctl default disable"
success "apt path writes expected files"
rm -rf "${TD}"

# 3) DNF path: inserts ip_resolve=4 and writes sysctl file
make_temp_env
stub_common_tools
stub_manager_presence dnf
# seed a minimal dnf.conf (without [main])
printf '%s\n' '# sample' > "${ETC}/dnf/dnf.conf"
run_script "1"
dnf_conf="${ETC}/dnf/dnf.conf"
[[ -f "${ETC}/dnf/dnf.conf.bak" ]] || fail "dnf backup not created"
[[ -f "$dnf_conf" ]] || fail "dnf.conf missing"
assert_in 'ip_resolve=4' "$(cat "$dnf_conf")" "DNF config should set ip_resolve=4"
[[ -f "${ETC}/sysctl.d/99-disable-ipv6.conf" ]] || fail "sysctl IPv6 disable file missing (dnf path)"
success "dnf path writes expected files"
rm -rf "${TD}"

# 4) pacman path: appends XferCommand with --ipv4
make_temp_env
stub_common_tools
stub_manager_presence pacman
# minimal pacman.conf without XferCommand
printf '%s\n' '[options]' > "${ETC}/pacman.conf"
run_script "true"
pacman_conf="${ETC}/pacman.conf"
[[ -f "$pacman_conf" ]] || fail "pacman.conf missing"
assert_in 'XferCommand = /usr/bin/curl' "$(cat "$pacman_conf")" "pacman XferCommand exists"
assert_in '--ipv4' "$(cat "$pacman_conf")" "pacman XferCommand enforces IPv4"
success "pacman path writes expected files"
rm -rf "${TD}"

success "force_ipv4.sh: all checks passed"

