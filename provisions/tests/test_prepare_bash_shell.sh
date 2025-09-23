#!/usr/bin/env bash
set -Eeuo pipefail
trap 'rc=$?; echo -e "\e[31m[TEST-ERROR]\e[0m $0:$LINENO: \"$BASH_COMMAND\" exited with $rc" >&2' ERR

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
ROOT_DIR="$(cd "${SCRIPT_DIR}/.." && pwd)"
export TEST_FAIL_FAST=1
source "${ROOT_DIR}/_utils.sh"

success "Now executing $(basename "$0")"

[[ -f "${HOME}/.bashrc" ]] || fail "~/.bashrc not found"

start_count="$(grep -c '^# BASHRC-CONFIG' "${HOME}/.bashrc" || true)"
end_count="$(grep -c '^# /BASHRC-CONFIG' "${HOME}/.bashrc" || true)"
assert_eq "1" "$start_count" "BASHRC-CONFIG start marker count should be 1"
assert_eq "1" "$end_count"   "BASHRC-CONFIG end marker count should be 1"

# check sourcing line (literal string)
needle='test -f ${HOME}/.bashrc-config && source ${HOME}/.bashrc-config'
bashrc_contents="$(cat "${HOME}/.bashrc")"
assert_in "$needle" "$bashrc_contents" "~/.bashrc should source ~/.bashrc-config"

success "prepare_bash_shell: all checks passed"
