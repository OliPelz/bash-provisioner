#!/bin/bash
set -euo pipefail
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
ROOT_DIR="$(cd "${SCRIPT_DIR}/.." && pwd)"
source "${ROOT_DIR}/_utils.sh"
log INFO "Now executing $(basename "${0}")"

rc=0
PASS(){ log INFO "✅ $*"; }
FAIL(){ log ERROR "❌ $*"; rc=1; }

if [ ! -f "${HOME}/.bashrc" ]; then
  FAIL "~/.bashrc not found"
  exit "$rc"
fi

start_count="$(grep -c '^# BASHRC-CONFIG' "${HOME}/.bashrc" || true)"
end_count="$(grep -c '^# /BASHRC-CONFIG' "${HOME}/.bashrc" || true)"

if [[ "$start_count" -eq 1 && "$end_count" -eq 1 ]]; then
  PASS "~/.bashrc contains one BASHRC-CONFIG block"
else
  FAIL "BASHRC-CONFIG block count not exactly 1 (start=$start_count end=$end_count)"
fi

if grep -q 'test -f ${HOME}/\.bashrc-config && source ${HOME}/\.bashrc-config' "${HOME}/.bashrc"; then
  PASS "~/.bashrc sources ~/.bashrc-config"
else
  FAIL "~/.bashrc missing source line for ~/.bashrc-config"
fi

if [ "$rc" -eq 0 ]; then PASS "prepare_bash_shell: all checks passed"; else FAIL "prepare_bash_shell: one or more checks failed"; fi
exit "$rc"
