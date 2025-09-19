#!/bin/bash
set -euo pipefail
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
ROOT_DIR="$(cd "${SCRIPT_DIR}/.." && pwd)"
source "${ROOT_DIR}/_utils.sh"
log INFO "Now executing $(basename "${0}")"

rc=0
PASS(){ log INFO "✅ $*"; }
FAIL(){ log ERROR "❌ $*"; rc=1; }

# dev_tools.sh promises a working build toolchain
for b in gcc make; do
  if command -v "$b" >/dev/null 2>&1; then
    PASS "binary available: $b"
  else
    FAIL "binary missing: $b"
  fi
done

if [ "$rc" -eq 0 ]; then PASS "dev_tools: all checks passed"; else FAIL "dev_tools: one or more checks failed"; fi
exit "$rc"
