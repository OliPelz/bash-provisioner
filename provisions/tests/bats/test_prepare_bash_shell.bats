#!/usr/bin/env bats
#set -x
if ! command -v bats >/dev/null; then
    printf "\033[0;32m[ERROR]\033[0m cannot find or exec bats"
    exit 1
fi


@test "~/.bashrc contains single BASHRC-CONFIG block and proper source line" {
  [ -f "${HOME}/.bashrc" ] || { echo "~/.bashrc not found"; false; }

  start_count="$(grep -c '^# BASHRC-CONFIG' "${HOME}/.bashrc" || true)"
  end_count="$(grep -c '^# /BASHRC-CONFIG' "${HOME}/.bashrc" || true)"
  [ "$start_count" -eq 1 ] || { echo "start marker count: $start_count"; false; }
  [ "$end_count"   -eq 1 ] || { echo "end marker count  : $end_count"  ; false; }

  needle='test -f ${HOME}/.bashrc-config && source ${HOME}/.bashrc-config'
  if ! grep -Fqx "$needle" "${HOME}/.bashrc"; then
    echo "~/.bashrc does not contain expected source line"
    false
  fi
}

