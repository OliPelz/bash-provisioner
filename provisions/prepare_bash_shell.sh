#!/usr/bin/env bash
set -Eeuo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
source "${SCRIPT_DIR}/_utils.sh"

log INFO "Now executing $(basename "${0}")"

check_commands_installed awk || { log ERROR "❌ Missing required commands."; exit 1; }

log INFO "🔄 Installing .bashrc-config in .bashrc"

if awk '/# BASHRC-CONFIG/,/\/BASHRC-CONFIG/' ~/.bashrc | grep -q '# BASHRC-CONFIG'; then
   echo "😎 BASHRC-CONFIG is already installed in ~/.bashrc ...bailing out"
   exit 0
fi

cat >> ~/.bashrc <<'EOF'
# BASHRC-CONFIG
test -f ${HOME}/.bashrc-config && source ${HOME}/.bashrc-config
# /BASHRC-CONFIG
EOF

log INFO "✅ Successfully installed .bashrc-config in .bashrc"
exit 0

