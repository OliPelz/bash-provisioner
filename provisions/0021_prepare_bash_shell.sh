#!/usr/bin/env bash
set -euo pipefail

echo "🔄 Installing .bashrc-config in .bashrc"

# idempotently add a source/load instruction of my custom bashrc-config to ~/.bashrc
if awk '/# BASHRC-CONFIG/,/\/BASHRC-CONFIG/' ~/.bashrc | grep -q '# BASHRC-CONFIG'; then
   echo "😎 BASHRC-CONFIG is already installed in ~/.bashrc ...bailing out"
   exit 0 
fi

echo '# BASHRC-CONFIG
source ${HOME}/.bashrc-config
# /BASHRC-CONFIG' >> ~/.bashrc

echo "✅ Successfully installed .bashrc-config in .bashrc"

exit 0
