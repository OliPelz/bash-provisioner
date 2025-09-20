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
  echo -e "${color}[$level] $timestamp $message${color_reset}" >&2

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
