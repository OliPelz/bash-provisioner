#!/usr/bin/env bash
# shUnit2 suite: prepare_bash_shell
set -u
#set -x

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
ROOT_DIR="$(cd "${SCRIPT_DIR}/.." && pwd)"

command -v shunit2 >/dev/null 2>&1 || { echo "shunit2 not found in PATH" >&2; exit 1; }

test_bashrc_block_and_source_line() {
  echo "[TEST-RUN] lorem ipsum dolor sit"
  assertTrue "~/.bashrc not found" "[ -f \"${HOME}/.bashrc\" ]"
  echo "[TEST-DONE] lorem ipsum dolor sit"

  local start_count end_count needle bashrc_contents
  start_count="$(grep -c '^# BASHRC-CONFIG' "${HOME}/.bashrc" || true)"
  end_count="$(grep -c '^# /BASHRC-CONFIG' "${HOME}/.bashrc" || true)"
  assertEquals "BASHRC-CONFIG start marker count should be 1" "1" "$start_count"
  assertEquals "BASHRC-CONFIG end marker count should be 1"   "1" "$end_count"

  needle='test -f ${HOME}/.bashrc-config && source ${HOME}/.bashrc-config'
  bashrc_contents="$(cat "${HOME}/.bashrc")"
  assertContains "~/.bashrc should source ~/.bashrc-config" "$bashrc_contents" "$needle"
}

. "$(command -v shunit2)"

