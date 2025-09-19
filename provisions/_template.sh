#!/bin/bash
set -euo pipefail

# --- Source section ---
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
source "${SCRIPT_DIR}/_utils.sh"

log INFO "Now executing $(basename "${0}")"

# --- Global variables check ---
: "${XXX:?must be set}"
: "${APP_XXX:?must be set}"

# --- Hard prerequisites ---
check_commands_installed TODO || {
   log ERROR "❌ Missing required commands." >&2
   exit 1
}

# --- Main role logic ---

log INFO "Doing a task xxxxxxxxx"

lorem ipsum dolor sit

# --- return 0 if OK ---
log INFO "✅ Successfully XXXX"
exit 0
