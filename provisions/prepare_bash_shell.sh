#!/bin/bash
set -euo pipefail

# --- Source section ---
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
source "${SCRIPT_DIR}/_utils.sh"

log INFO "Now executing $(basename "${0}")"

# --- Global variables check ---
# : "${XXX:?must be set}"
# : "${APP_XXX:?must be set}"

# --- Hard prerequisites ---
check_commands_installed awk || {
   log ERROR "❌ Missing required commands." >&2
   exit 1
}

# --- Main role logic ---

log INFO "🔄 Installing .bashrc-config in .bashrc"

# idempotently add a source/load instruction of my custom bashrc-config to ~/.bashrc
if awk '/# BASHRC-CONFIG/,/\/BASHRC-CONFIG/' ~/.bashrc | grep -q '# BASHRC-CONFIG'; then
   echo "😎 BASHRC-CONFIG is already installed in ~/.bashrc ...bailing out"
   exit 0 
fi

echo '
# BASHRC-CONFIG
test -f ${HOME}/.bashrc-config && source ${HOME}/.bashrc-config
# /BASHRC-CONFIG' >> ~/.bashrc

# --- return 0 if OK ---
log INFO "✅ Successfully installed .bashrc-config in .bashrc"
exit 0
