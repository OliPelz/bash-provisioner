# --- global logic

# prechecks when sourcing or running this script
# possible values: development, test, production
RUN_ENV="${RUN_ENV:-development}" 
# Get the directory of the current file being sourced
PROV_UTILS_FILE_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"

for the_file in global_env.sh env_$RUN_ENV.sh credentials_$RUN_ENV.sh; do
   if ! [[ -f "${PROV_UTILS_FILE_DIR}/env/${the_file}" ]]; then
       echo -e "\033[31m[ERROR] $(date +%s) Could not find essential file: ${the_file}...bailing out! \033[0m" >&2
       return 1
   fi
   source ${PROV_UTILS_FILE_DIR}/env/${the_file}
done

if [[ "${CREDENTIALS_READABLE:-}" != "itworks" ]]; then
       echo -e "\033[31m[ERROR] $(date +%s) Could not properly read credentials file '${PROV_UTILS_FILE_DIR}/env/credentials_${RUN_ENV}.sh' or could not properly decrypt it...bailing out! \033[0m" >&2
       return 1
fi

# --- functions

_log_level_rank() {
  : '
  v0.0.1
'
  case "${1}" in
    TRACE) echo 0 ;;
    DEBUG) echo 1 ;;
    INFO)  echo 2 ;;
    WARN|WARNING) echo 3 ;;
    ERROR) echo 4 ;;
    FATAL) echo 5 ;;
    *) echo 9 ;;  # Unknown levels get highest rank
  esac
}

log() {
  : '
      v0.0.1
  '
  local level="$1"
  shift
  local message="${*}"
  local timestamp
  timestamp=$(date '+%Y-%m-%d %H:%M:%S')

  local current_rank=$(_log_level_rank "${LOG_LEVEL:-INFO}")
  local message_rank=$(_log_level_rank "$level")

  if (( message_rank < current_rank )); then
    return
  fi

  local color_reset=""
  local color=""

  # Apply colors only if output is a TTY (terminal)
  if [ -t 1 ]; then
    color_reset="\033[0m"
    case "${level}" in
      TRACE) color="\033[90m" ;;     # Bright Black / Gray
      DEBUG) color="\033[36m" ;;     # Cyan
      INFO)  color="\033[32m" ;;     # Green
      WARN|WARNING) color="\033[33m" ;; # Yellow
      ERROR) color="\033[31m" ;;     # Red
      FATAL) color="\033[1;31m" ;;   # Bold Red
      *) color="" ;;
    esac
  fi
  # Note: always log to stderr
  # Output to stderr with timestamp and color formatting
  echo -e "${color}[${level}] ${timestamp} ${message}${color_reset}" >&2

  # Exit immediately on fatal errors
  if [[ "${level}" == "FATAL" ]]; then
    exit 1
  fi
}

detect_linux_distro() {
: '
v.0.0.1
'
  if [[ -f /etc/os-release ]]; then
    # shellcheck disable=SC1091
    . /etc/os-release
    LINUX_DISTRO="${ID,,}" # ensure lowercase
    # return linux distro name
    echo "$LINUX_DISTRO"
    return 0
  else
    log ERROR "❌ Could not detect distribution: /etc/os-release missing"
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


#### -- bash mini test framework functions ---

# --- mini-test.sh -------------------------------------------------------------
# A tiny Bash test helper: assert_eq, assert_in, success, fail + colored summary.

# Config
TEST_FAIL_FAST="${TEST_FAIL_FAST:-0}"   # set to 1 to exit on first failure
TEST_NAME="${TEST_NAME:-}"              # optional suite name printed in summary

# Colors (disabled if not a TTY or NO_COLOR=1)
if [[ -t 1 && "${NO_COLOR:-0}" != "1" ]]; then
  RED=$'\033[0;31m'; GREEN=$'\033[0;32m'; YELLOW=$'\033[1;33m'
  BLUE=$'\033[0;34m'; BOLD=$'\033[1m'; DIM=$'\033[2m'; NC=$'\033[0m'
else
  RED=""; GREEN=""; YELLOW=""; BLUE=""; BOLD=""; DIM=""; NC=""
fi

# State
__TESTS_PASSED=0
__TESTS_FAILED=0
__TESTS_TOTAL=0

# Utility: print summary (called automatically on exit)
_test_summary() {
  local status="${GREEN}✓ PASSED${NC}"
  (( __TESTS_FAILED > 0 )) && status="${RED}✗ FAILED${NC}"
  printf "\n${BLUE}--- Test Summary${NC}%s\n" ""
  [[ -n "$TEST_NAME" ]] && printf "%s\n" "${BOLD}${TEST_NAME}${NC}"
  printf "  total : %d\n" "$__TESTS_TOTAL"
  printf "  pass  : %b%d%b\n" "$GREEN" "$__TESTS_PASSED" "$NC"
  printf "  fail  : %b%d%b\n" "$RED" "$__TESTS_FAILED" "$NC"
  printf "  result: %s\n" "$status"
  # Return non-zero if there were failures
  (( __TESTS_FAILED > 0 )) && return 1 || return 0
}

# Auto-summary on exit
trap '_test_summary' EXIT

# ----- public API -------------------------------------------------------------




# --- _utils.sh: minimal test helpers -----------------------------------------

# Colors
if [[ -t 1 && "${NO_COLOR:-0}" != "1" ]]; then
  RED=$'\033[0;31m'; GREEN=$'\033[0;32m'; YELLOW=$'\033[1;33m'; BLUE=$'\033[0;34m'; NC=$'\033[0m'; BOLD=$'\033[1m'; DIM=$'\033[2m'
else
  RED=; GREEN=; YELLOW=; BLUE=; NC=; BOLD=; DIM=
fi

# State
: "${TEST_FAIL_FAST:=0}"
declare -gi __TESTS_PASSED=0 __TESTS_FAILED=0 __TESTS_TOTAL=0

_test_summary() {
  local status="${GREEN}✓ PASSED${NC}"
  (( __TESTS_FAILED > 0 )) && status="${RED}✗ FAILED${NC}"
  printf "\n${BLUE}--- Test Summary${NC}\n"
  printf "  total : %d\n" "$__TESTS_TOTAL"
  printf "  pass  : %b%d%b\n" "$GREEN" "$__TESTS_PASSED" "$NC"
  printf "  fail  : %b%d%b\n" "$RED" "$__TESTS_FAILED" "$NC"
  printf "  result: %s\n" "$status"
  (( __TESTS_FAILED == 0 ))
}

# Ensure we only set the trap once even if sourced multiple times
if [[ -z "${__TEST_TRAP_SET:-}" ]]; then
  trap '_test_summary' EXIT
  __TEST_TRAP_SET=1
fi

success() {
  # success [message]
  local msg="${1:-OK}"
  printf "%b[INFO]%b %s\n" "$BLUE" "$NC" "$msg"
  (( ++__TESTS_PASSED ))
  (( ++__TESTS_TOTAL ))
  return 0
}

fail() {
  # fail message [details]
  local msg="${1:-Assertion failed}"
  local details="${2:-}"
  printf "%b[ERROR]%b %s\n" "$RED" "$NC" "$msg" 1>&2
  [[ -n "$details" ]] && printf "        %s\n" "$details" 1>&2
  (( ++__TESTS_FAILED ))
  (( ++__TESTS_TOTAL ))
  if [[ "$TEST_FAIL_FAST" == "1" ]]; then
    _test_summary >/dev/null
    exit 1
  fi
  return 1
}

assert_eq() {
  # assert_eq expected actual [message]
  local expected="$1" actual="$2" msg="${3:-values should be equal}"
  if [[ "$actual" == "$expected" ]]; then
    success "$msg"
  else
    fail "$msg: expected '$expected', got '${actual:-<none>}'"
  fi
}

assert_in() {
  # assert_in needle haystack [message]
  local needle="$1" haystack="$2" msg="${3:-haystack should contain needle}"
  if [[ "$haystack" == *"$needle"* ]]; then
    success "$msg"
  else
    fail "$msg: needle '$needle' not found"
  fi
}


##############################################




# Wait until apt/dpkg are free
apt_wait() {
  local locks=(/var/lib/dpkg/lock-frontend /var/lib/apt/lists/lock /var/cache/apt/archives/lock)
  for svc in apt-daily.service apt-daily-upgrade.service; do
    systemctl list-unit-files --type=service --no-legend 2>/dev/null | grep -q "^${svc}" &&
      while systemctl is-active --quiet "$svc"; do sleep 2; done
  done
  while :; do
    local busy=0
    for f in "${locks[@]}"; do fuser -s "$f" 2>/dev/null && { busy=1; break; }; done
    ((busy==0)) && break
    sleep 2
  done
}

# Strict update: fail on *any* error and force IPv4
apt_update_strict() {
  apt_wait
  # capture output to inspect it *and* keep correct exit code
  local log; log="$(mktemp)"; trap 'rm -f "$log"' RETURN

  # APT::Update::Error-Mode=any -> treat any fetch/index error as fatal (supported on modern apt)
  # Force IPv4 to avoid your IPv6 "Network is unreachable"
  if ! sudo -E apt-get update \
        -o Acquire::ForceIPv4=true \
        -o Dpkg::Lock::Timeout=600 \
        -o Acquire::Retries=3 \
        -o APT::Update::Error-Mode=any \
        2>&1 | tee "$log"; then
    echo "apt-get update failed (non-zero exit)"; return 1
  fi

  # Some apt versions still return 0 but warn; treat those as failure
  if grep -qE '^(W: Failed to fetch|E: Failed to fetch|Err:)' "$log"; then
    echo "apt-get update encountered fetch errors" >&2
    return 1
  fi
}

# Safe “install/upgrade” wrapper (noninteractive, retries)
apt_safe() {
  apt_wait
  sudo -E DEBIAN_FRONTEND=noninteractive NEEDRESTART_MODE=a \
    apt-get -yq \
      -o Dpkg::Lock::Timeout=600 \
      -o Acquire::Retries=3 \
      -o Dpkg::Options::="--force-confdef" \
      -o Dpkg::Options::="--force-confold" \
      "$@"
}

