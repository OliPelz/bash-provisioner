#!/usr/bin/env bash
# shUnit2 suite: dev tools
set -u

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
ROOT_DIR="$(cd "${SCRIPT_DIR}/.." && pwd)"

command -v shunit2 >/dev/null 2>&1 || { echo "shunit2 not found in PATH" >&2; exit 1; }

test_dev_toolchain_binaries() {
  for b in gcc make; do
    assertTrue "binary missing: $b" "command -v $b >/dev/null 2>&1"
  done
}

. "$(command -v shunit2)"

