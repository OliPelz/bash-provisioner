#!/usr/bin/env bash
# shUnit2 suite: force_ipv4.sh
set -u

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
ROOT_DIR="$(cd "${SCRIPT_DIR}/.." && pwd)"
UNDER_TEST="${ROOT_DIR}/force_ipv4.sh"

command -v shunit2 >/dev/null 2>&1 || { echo "shunit2 not found in PATH" >&2; exit 1; }

make_temp_env() {
  TD="$(mktemp -d)"; export TD
  ETC="${TD}/etc"; mkdir -p "${ETC}"/{apt/apt.conf.d,dnf,sysctl.d}
  BIN="${TD}/bin"; mkdir -p "${BIN}"
  export TEST_ETC="${TD}"
  export PATH="${BIN}:${PATH}"
}

stub_common_tools() {
  cat > "${BIN}/sudo" <<'EOF'; chmod +x "${BIN}/sudo"
#!/usr/bin/env bash
exec "$@"
EOF
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
  cat > "${BIN}/awk" <<'EOF'; chmod +x "${BIN}/awk"
#!/usr/bin/env bash
set -Eeuo pipefail
mapped=()
for a in "$@"; do
  [[ "$a" == /etc/* ]] && mapped+=("${TEST_ETC}$a") || mapped+=("$a")
done
exec /usr/bin/awk "${mapped[@]}"
EOF
  cat > "${BIN}/grep" <<'EOF'; chmod +x "${BIN}/grep"
#!/usr/bin/env bash
set -Eeuo pipefail
mapped=()
for a in "$@"; do
  [[ "$a" == /etc/* ]] && mapped+=("${TEST_ETC}$a") || mapped+=("$a")
done
exec /bin/grep "${mapped[@]}"
EOF
  cat > "${BIN}/sysctl" <<'EOF'; chmod +x "${BIN}/sysctl"
#!/usr/bin/env bash
exit 0
EOF
}

stub_manager_presence() {
  local want="${1:-}"
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
  DISABLE_IPV6="${1:-}" TEST_ETC="${TEST_ETC}" PATH="${PATH}" bash -Eeuo pipefail "${UNDER_TEST}"
}

test_early_exit_when_not_disabled() {
  make_temp_env; stub_common_tools; stub_manager_presence none
  run_script ""
  assertTrue "apt conf should not exist when IPv6 not disabled" "[[ ! -e \"${ETC}/apt/apt.conf.d/99force-ipv4\" ]]"
  assertTrue "sysctl conf should not exist when IPv6 not disabled" "[[ ! -e \"${ETC}/sysctl.d/99-disable-ipv6.conf\" ]]"
  rm -rf "${TD}"
}

test_apt_path_writes_expected_files() {
  make_temp_env; stub_common_tools; stub_manager_presence apt
  run_script "true"
  local apt_conf="${ETC}/apt/apt.conf.d/99force-ipv4"
  assertTrue "APT force IPv4 file missing" "[ -f \"$apt_conf\" ]"
  assertContains "APT config should force IPv4" "$(cat "$apt_conf")" 'Acquire::ForceIPv4 "true";'

  local sysctl_conf="${ETC}/sysctl.d/99-disable-ipv6.conf"
  assertTrue "sysctl IPv6 disable file missing" "[ -f \"$sysctl_conf\" ]"
  assertContains "sysctl all disable"     "$(cat "$sysctl_conf")" 'net.ipv6.conf.all.disable_ipv6=1'
  assertContains "sysctl default disable" "$(cat "$sysctl_conf")" 'net.ipv6.conf.default.disable_ipv6=1'
  rm -rf "${TD}"
}

test_dnf_path_writes_expected_files() {
  make_temp_env; stub_common_tools; stub_manager_presence dnf
  printf '%s\n' '# sample' > "${ETC}/dnf/dnf.conf"
  run_script "1"
  assertTrue "dnf backup not created" "[ -f \"${ETC}/dnf/dnf.conf.bak\" ]"
  local dnf_conf="${ETC}/dnf/dnf.conf"
  assertTrue "dnf.conf missing" "[ -f \"$dnf_conf\" ]"
  assertContains "DNF config should set ip_resolve=4" "$(cat "$dnf_conf")" 'ip_resolve=4'
  assertTrue "sysctl IPv6 disable file missing (dnf path)" "[ -f \"${ETC}/sysctl.d/99-disable-ipv6.conf\" ]"
  rm -rf "${TD}"
}

test_pacman_path_writes_expected_files() {
  make_temp_env; stub_common_tools; stub_manager_presence pacman
  printf '%s\n' '[options]' > "${ETC}/pacman.conf"
  run_script "true"
  local pacman_conf="${ETC}/pacman.conf"
  assertTrue "pacman.conf missing" "[ -f \"$pacman_conf\" ]"
  assertContains "pacman XferCommand exists"   "$(cat "$pacman_conf")" 'XferCommand = /usr/bin/curl'
  assertContains "pacman XferCommand enforces IPv4" "$(cat "$pacman_conf")" '--ipv4'
  rm -rf "${TD}"
}

. "$(command -v shunit2)"

