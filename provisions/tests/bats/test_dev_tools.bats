#!/usr/bin/env bats

@test "dev toolchain binaries present (gcc make)" {
  for b in gcc make; do
    if ! command -v "$b" >/dev/null 2>&1; then
      echo "binary missing: $b"
      false
    fi
  done
}

