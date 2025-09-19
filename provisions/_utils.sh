detect_linux_distro() {
: '
v.0.0.1
'
  if [[ -f /etc/os-release ]]; then
    # shellcheck disable=SC1091
    . /etc/os-release
    LINUX_DISTRO="${ID,,}" # ensure lowercase
    echo "Detected Linux distribution: $LINUX_DISTRO"
    return 0
  else
    echo "❌ Could not detect distribution: /etc/os-release missing"
    return 1
  fi
}

check_commands_installed() {
: '
v.0.0.1
'
  local missing_commands=()
  local cmd

  for cmd in "$@"; do
    if ! command -v "${cmd}" &>/dev/null; then
      missing_commands+=("${cmd}")
    fi
  done

  if [[ ${#missing_commands[@]} -gt 0 ]]; then
    log ERROR "Required commands not found: ${missing_commands[*]}"
    return 1
  fi

  return 0
}
