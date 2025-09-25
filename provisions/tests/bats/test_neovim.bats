#!/usr/bin/env bats

setup() {
  export PATH="$HOME/bin:$PATH"
  export NEOVIM_VERSION="${NEOVIM_VERSION:-0.10.2}"
}

@test "Neovim symlink exists and version matches" {
  if [[ ! -L "$HOME/bin/neovim" ]]; then
    echo "Neovim symlink missing at \$HOME/bin/neovim"
    false
  fi

  tgt="$(readlink -f "$HOME/bin/neovim" || true)"
  [ -n "$tgt" ] && [ -x "$tgt" ] || { echo "Neovim link target not executable: ${tgt:-<none>}"; false; }

  reported_raw="$("$HOME/bin/neovim" --version | awk 'NR==1{print $2}')"
  reported_norm="$(printf '%s' "$reported_raw" | sed -E 's/^v//')"

  if [[ "$reported_norm" != "$NEOVIM_VERSION" ]]; then
    echo "expected: $NEOVIM_VERSION"
    echo "actual  : $reported_norm"
    false
  fi
}

