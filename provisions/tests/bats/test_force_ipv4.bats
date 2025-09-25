#!/usr/bin/env bats

# These tests stub system tools so force_ipv4.sh writes under a temp /etc

setup() {
  [ -f "./force_ipv4.sh" ] || skip "force_ipv4.sh not found in CWD"

  TD="$(mktemp -d)"
  ETC="${TD}/etc"
  BIN="${TD}/bin"
  mkdir -p "${ETC}"/{apt/apt.conf.d,dnf,sysctl.d} "${BIN}"
  export TEST_ETC="${TD}"
  export PATH="${BIN}:$PATH"

  # --- stubs used by the script ---

  # sudo: pass-through
  cat > "${BIN}/sudo" <<'EOF'
#!/usr/bin/env bash
exec "$@"
EOF
  chmod +x "${BIN}/sudo"

  # tee: map /etc -> $TEST_ETC/etc and create parents; honor -a
  cat > "${BIN}/tee" <<'EOF'
#!/usr/bin/env bash
set -Eeuo pipefail
map_path(){ [[ "$1" == /etc/* ]] && echo "${TEST_ETC}$1" || echo "$1"; }
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
  chmod +x "${BIN}/tee"

  # cp: map /etc paths
  cat > "${BIN}/cp" <<'EOF'
#!/usr/bin/env bash
set -Eeuo pipefail
map(){ [[ "$1" == /etc/* ]] && echo "${TEST_ETC}$1" || echo "$1"; }
dest="$(map "${@: -1}")"
mkdir -p "$(dirname "$dest")"
mapped=()
for a in "$@"; do mapped+=("$(map "$a")"); done
exec /bin/cp "${mapped[@]}"
EOF
  chmod +x "${BIN}/cp"

  # awk/grep/sysctl as safe stubs
  printf '%s\n' '#!/usr/bin/env bash' 'exec /usr/bin/awk "$@"'   > "${BIN}/awk";    chmod +x "${BIN}/awk"
  printf '%s\n' '#!/usr/bin/env bash' 'exec /bin/grep "$@"'      > "${BIN}/grep";   chmod +x "${BIN}/grep"
  printf '%s\n' '#!/usr/bin/env bash' 'exit 0'                   > "${BIN}/sysctl"; chmod +x "${BIN}/sysctl"
}

teardown() {
  rm -rf "$TD"
}

# Helper to simulate which PM is present for a given test
_pm_stub() {
  local want="${1:-}"  # apt | dnf | pacman | none
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
  DISABLE_IPV6="${1:-}" TEST_ETC="${TEST_ETC}" PATH="${PATH}" bash -Eeuo pipefail ./force_ipv4.sh
}

@test "no-op when DISABLE_IPV6 is not set/true" {
  _pm_stub none
  run run_script ""
  [ "$status" -eq 0 ]
  [ ! -e "${ETC}/apt/apt.conf.d/99force-ipv4" ]
  [ ! -e "${ETC}/sysctl.d/99-disable-ipv6.conf" ]
}

@test "APT path: creates ForceIPv4 and sysctl files" {
  _pm_stub apt
  run run_script "true"
  [ "$status" -eq 0 ]

  [ -f "${ETC}/apt/apt.conf.d/99force-ipv4" ]
  grep -q 'Acquire::ForceIPv4 "true";' "${ETC}/apt/apt.conf.d/99force-ipv4"

  [ -f "${ETC}/sysctl.d/99-disable-ipv6.conf" ]
  grep -q 'net\.ipv6\.conf\.all\.disable_ipv6=1'    "${ETC}/sysctl.d/99-disable-ipv6.conf"
  grep -q 'net\.ipv6\.conf\.default\.disable_ipv6=1' "${ETC}/sysctl.d/99-disable-ipv6.conf"
}

@test "DNF path: injects ip_resolve=4 and writes sysctl file" {
  _pm_stub dnf
  echo '# sample' > "${ETC}/dnf/dnf.conf"

  run run_script "1"
  [ "$status" -eq 0 ]

  [ -f "${ETC}/dnf/dnf.conf.bak" ]
  [ -f "${ETC}/dnf/dnf.conf" ]
  grep -q 'ip_resolve=4' "${ETC}/dnf/dnf.conf"
  [ -f "${ETC}/sysctl.d/99-disable-ipv6.conf" ]
}

@test "pacman path: appends XferCommand with --ipv4" {
  _pm_stub pacman
  echo '[options]' > "${ETC}/pacman.conf"

  run run_script "true"
  [ "$status" -eq 0 ]

  grep -q 'XferCommand = /usr/bin/curl' "${ETC}/pacman.conf"
  grep -q -- '--ipv4' "${ETC}/pacman.conf"
}

