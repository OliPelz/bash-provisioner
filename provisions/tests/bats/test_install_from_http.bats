#!/usr/bin/env bats

setup() {
  export PATH="$HOME/bin:$PATH"
}

@test "installed gzip tarball tools are symlinked and executable" {
  # name|extract-dir|binary-relative
  entries=(
    "keychain|keychain-2.8.5|keychain"
    "geckodriver|geckodriver-v0.34.0|geckodriver"
    "hurl|hurl-4.2.0|hurl"
    "git-trim|git-trim-v0.4.3|git-trim"
    "starship|starship-v1.17.1|starship"
    "mcfly|mcfly-v0.8.4|mcfly"
  )

  for e in "${entries[@]}"; do
    IFS='|' read -r name extract rel <<<"$e"
    link="$HOME/bin/$name"
    dest="$HOME/bin/${name}-versions/${extract}/${rel}"

    if [[ ! -L "$link" ]]; then echo "$name symlink missing: $link"; false; fi
    if [[ ! -f "$dest" ]]; then echo "$name target missing: $dest"; false; fi
    if [[ ! -x "$dest" ]]; then echo "$name target not executable: $dest"; false; fi
  done
}

@test "subset binaries respond to --version" {
  for b in geckodriver hurl starship git-trim; do
    if ! command -v "$b" >/dev/null 2>&1; then echo "$b not on PATH"; false; fi
    run "$b" --version
    [ "$status" -eq 0 ]
  done
}

