#!/bin/bash
set -euo pipefail
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
ROOT_DIR="$(cd "${SCRIPT_DIR}/.." && pwd)"
source "${ROOT_DIR}/_utils.sh"
log INFO "Now executing $(basename "${0}")"

rc=0
PASS(){ log INFO "✅ $*"; }
FAIL(){ log ERROR "❌ $*"; rc=1; }

export PATH="$HOME/bin:$PATH"
NEOVIM_VERSION="${NEOVIM_VERSION:-0.10.2}"
EXPECTED="v${NEOVIM_VERSION}"

if [ -L "$HOME/bin/neovim" ]; then
  tgt="$(readlink -f "$HOME/bin/neovim" || true)"
  if [[ -x "$tgt" ]]; then
    reported="$("$HOME/bin/neovim" --version | awk 'NR==1{print $2}')"
    if [[ "$reported" == "$EXPECTED" ]]; then
      PASS "Neovim present and version matches ($reported)"
    else
      FAIL "Neovim version mismatch: expected $EXPECTED, got ${reported:-<none>}"
    fi
  else
    FAIL "Neovim link target not executable: ${tgt:-<none>}"
  fi
else
  FAIL "Neovim symlink missing at \$HOME/bin/neovim"
fi

if [ "$rc" -eq 0 ]; then PASS "neovim: all checks passed"; else FAIL "neovim: one or more checks failed"; fi
exit "$rc"
