#!/usr/bin/env bats

@test "host reports no pending package upgrades (apt/pacman/dnf)" {
  if command -v apt >/dev/null 2>&1; then
    # Filter header line
    upgradable="$(apt list --upgradable 2>/dev/null | awk 'NR>1')"
    if [[ -n "$upgradable" ]]; then
      echo "APT shows pending upgrades:"
      printf '%s\n' "$upgradable"
      false
    fi

  elif command -v pacman >/dev/null 2>&1; then
    if pacman -Qu 2>/dev/null | grep -q .; then
      echo "pacman shows pending upgrades:"
      pacman -Qu 2>/dev/null | sed 's/^/   - /' || true
      false
    fi

  elif command -v dnf >/dev/null 2>&1; then
    # dnf returns 100 when updates are available, 0 when none, other values = error
    dnf -q check-update >/dev/null 2>&1
    code=$?
    if [[ "$code" -eq 100 ]]; then
      echo "DNF shows pending upgrades:"
      dnf -q check-update || true
      false
    elif [[ "$code" -ne 0 ]]; then
      echo "DNF check-update returned error code $code"
      false
    fi

  else
    skip "Unsupported or unknown package manager; cannot verify update state"
  fi
}

