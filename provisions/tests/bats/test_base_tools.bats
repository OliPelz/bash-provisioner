#!/usr/bin/env bats

setup() {
  export PATH="$HOME/bin:$PATH"
  # Respect host-provisioned version (or default)
  export YQ_VERSION="${YQ_VERSION:-4.45.1}"
}

# helper: some tools might live in sbin
has_bin() {
  local b="$1"
  command -v "$b" >/dev/null 2>&1 && return 0
  local p
  for p in /usr/sbin /sbin /usr/local/sbin; do
    [[ -x "$p/$b" ]] && return 0
  done
  return 1
}

@test "yq symlink exists and version matches \$YQ_VERSION" {
  if [[ ! -L "$HOME/bin/yq" ]]; then
    echo "yq symlink missing at \$HOME/bin/yq"
    false
  fi

  target="$(readlink -f "$HOME/bin/yq" || true)"
  [ -n "$target" ] || { echo "yq symlink target is empty"; false; }
  [ -f "$target" ] || { echo "yq symlink target missing: ${target:-<none>}"; false; }
  [ -x "$target" ] || { echo "yq symlink target not executable: $target"; false; }

  installed_raw="$("$HOME/bin/yq" --version 2>/dev/null || true)"
  installed="$(printf '%s' "$installed_raw" | sed -E 's/.*v?([0-9]+\.[0-9]+\.[0-9]+).*/\1/')"
  if [[ "$installed" != "$YQ_VERSION" ]]; then
    echo "expected: $YQ_VERSION"
    echo "actual  : $installed"
    false
  fi
}

@test "base binaries present (htop xclip tmux jq curl)" {
  for b in htop xclip tmux jq curl; do
    if ! has_bin "$b"; then
      echo "binary missing: $b"
      false
    fi
  done
}

@test "net-tools present (ifconfig or netstat)" {
  if has_bin ifconfig || has_bin netstat; then
    : # ok
  else
    echo "net-tools not found (ifconfig/netstat)"
    false
  fi
}

@test "optional info: package manager reports installed (non-fatal)" {
  if command -v dpkg >/dev/null 2>&1; then
    for p in htop net-tools xclip tmux jq curl; do
      dpkg -s "$p" >/dev/null 2>&1 || echo "dpkg does not confirm installed: $p"
    done
  elif command -v pacman >/dev/null 2>&1; then
    for p in htop net-tools xclip tmux jq curl; do
      pacman -Q "$p" >/dev/null 2>&1 || echo "pacman does not confirm installed: $p"
    done
  elif command -v rpm >/dev/null 2>&1; then
    for p in htop net-tools xclip tmux jq curl; do
      rpm -q "$p" >/dev/null 2>&1 || echo "rpm does not confirm installed: $p"
    done
  else
    skip "no known package manager present"
  fi
}
