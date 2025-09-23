#!/usr/bin/env bash
set -Eeuo pipefail
trap 'rc=$?; echo -e "\e[31m[TEST-ERROR]\e[0m $0:$LINENO: \"$BASH_COMMAND\" exited with $rc" >&2' ERR

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
ROOT_DIR="$(cd "${SCRIPT_DIR}/.." && pwd)"
export TEST_FAIL_FAST=1
source "${ROOT_DIR}/_utils.sh"

success "Now executing $(basename "$0")"

export PATH="$HOME/bin:$PATH"
NEOVIM_VERSION="${NEOVIM_VERSION:-0.10.2}"

[[ -L "$HOME/bin/neovim" ]] || fail "Neovim symlink missing at \$HOME/bin/neovim"

tgt="$(readlink -f "$HOME/bin/neovim" || true)"
[[ -n "$tgt" && -x "$tgt" ]] || fail "Neovim link target not executable: ${tgt:-<none>}"

reported_raw="$("$HOME/bin/neovim" --version | awk 'NR==1{print $2}')"
reported_norm="$(printf '%s' "$reported_raw" | sed -E 's/^v//')"
assert_eq "$NEOVIM_VERSION" "$reported_norm" "Neovim version should match"
success "Neovim present and version matches ($reported_raw)"

success "neovim: all checks passed"

