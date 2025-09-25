#!/usr/bin/env bash
set -Eeuo pipefail
# set -x

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
source "${SCRIPT_DIR}/_utils.sh"

log INFO "Now executing $(basename "${0}")"

# we need this for our custom yq
export PATH="$HOME/bin/:$PATH"

check_commands_installed file ldconfig ldd yq mkdir test ln pcurl_wrapper sudo tar awk grep sed find mktemp || {
  log ERROR "❌ Missing required commands."; exit 1; }

if [[ ! -f "$SCRIPT_DIR/install_from_http.yaml" ]]; then
  log ERROR "cannot find mandatory file: $SCRIPT_DIR/install_from_http.yaml...bailing out"
  exit 1
fi

# --------------------------- lib presence checks ------------------------------
# Accepts either a base token (e.g., "libxml2" or "z") or a full soname (e.g., "libxml2.so.2").
# Returns 0 if a matching library is found via ldconfig cache OR common lib paths.
_lib_present() {
  local tok="$1"
  local so_pat
  if [[ "$tok" == lib*.so* ]]; then
    # exact-ish soname pattern, e.g. libxml2.so.2
    so_pat="$tok"
  else
    # base name; allow any lib<tok>.so or lib<tok>.so.*
    # common shorthand: "z" → libz.so*
    so_pat="lib${tok}.so"
  fi

  # 1) Try ldconfig cache if available (portable across Arch/RHEL/Ubuntu)
  if command -v ldconfig >/dev/null 2>&1; then
    if ldconfig -p 2>/dev/null | awk '{print $1}' | grep -Eq "^${so_pat}(\.|$)"; then
      return 0
    fi
  fi

  # 2) Fallback: scan common library paths
  local d
  for d in /lib /lib64 /usr/lib /usr/lib64 /usr/local/lib /usr/local/lib64 /lib/x86_64-linux-gnu /usr/lib/x86_64-linux-gnu; do
    [[ -d "$d" ]] || continue
    if compgen -G "${d}/${so_pat}*" >/dev/null; then
      return 0
    fi
  done
  return 1
}

# Pretty-print array items one per line, indented.
_pp_list() {
  local item
  for item in "$@"; do
    printf '    - %s\n' "$item"
  done
}

# Detect if a .tar.gz has a single top-level directory.
# Echoes "1" if yes (safe to --strip-components=1), else "0".
_tar_has_single_toplevel() {
  local tarfile="$1"
  local first top
  first="$(tar -tzf "$tarfile" 2>/dev/null | head -n1 || true)"
  [[ -z "$first" ]] && { echo 0; return 0; }
  top="${first%%/*}"
  [[ "$first" == */* ]] || { echo 0; return 0; }
  if tar -tzf "$tarfile" 2>/dev/null | awk -v t="$top" 'index($0, t"/")==1 {ok++} END{exit (ok==0)}'; then
    echo 1
  else
    echo 0
  fi
}

log INFO "Installing software from http(s)"
mkdir -p "$HOME/bin"

overall_missing=0
missing_report=""

# Helper to canonicalize a lib token to a stem with lib-prefix (for de-dupe)
_canon_lib() {
  local t="$1"
  if [[ "$t" == lib*.so* ]]; then
    printf '%s\n' "${t%%.so*}"            # libxml2.so.2 -> libxml2
  elif [[ "$t" == lib* ]]; then
    printf '%s\n' "$t"                    # libxml2 -> libxml2
  else
    printf 'lib%s\n' "$t"                 # z -> libz
  fi
}

# Build the list once (avoid subshell pipeline that would hide set -e errors).
_list_file="$(mktemp)"
trap 'rm -f "$_list_file" || true' EXIT

yq -r '((.binary_gz_tar_balls // .gz_tar_balls // [])[] |
        "\(.link_name)|\(.extract_dir)|\(.path_to_bin)|\(.download_url)")' \
  "$SCRIPT_DIR/install_from_http.yaml" > "$_list_file"

# Iterate without a subshell so counters/vars persist.
while IFS='|' read -r LINK_NAME EXTRACT_DIR PATH_TO_BIN DOWNLOAD_URL; do
  [[ -n "${LINK_NAME:-}" ]] || continue

  DEST_DIR="$HOME/bin/$LINK_NAME-versions/$EXTRACT_DIR"
  mkdir -p "$DEST_DIR"

  # Always download to a temp file so we can inspect/extract robustly
  tmp_tgz="$(mktemp)"

  if [[ ! -f "$DEST_DIR/$PATH_TO_BIN" ]]; then
    log INFO "Downloading ${LINK_NAME} from ${DOWNLOAD_URL}"
    pcurl_wrapper -L -o "$tmp_tgz" "$DOWNLOAD_URL"

    # Decide strip-components based on tar layout
    if [[ "$(_tar_has_single_toplevel "$tmp_tgz")" == "1" ]]; then
      tar -xzf "$tmp_tgz" -C "$DEST_DIR" --strip-components=1
    else
      tar -xzf "$tmp_tgz" -C "$DEST_DIR"
    fi

    # If the declared PATH_TO_BIN is not found, try to locate it (maxdepth 2).
    if [[ ! -e "$DEST_DIR/$PATH_TO_BIN" ]]; then
      cand="$(find "$DEST_DIR" -maxdepth 2 -type f -name "$(basename "$PATH_TO_BIN")" -print -quit || true)"
      if [[ -n "$cand" ]]; then
        log INFO "Resolved ${LINK_NAME} binary at ${cand} (auto-detected)."
        RESOLVED_BIN="$cand"
      else
        rm -f "$tmp_tgz" || true
        log ERROR "Could not find binary for ${LINK_NAME}. Expected '${DEST_DIR}/${PATH_TO_BIN}'."
        exit 1
      fi
    else
      RESOLVED_BIN="$DEST_DIR/$PATH_TO_BIN"
    fi

    # Ensure executable
    if [[ -f "$RESOLVED_BIN" && ! -x "$RESOLVED_BIN" ]]; then
      chmod +x "$RESOLVED_BIN" || { rm -f "$tmp_tgz" || true; log ERROR "Failed to chmod +x ${RESOLVED_BIN}"; exit 1; }
      log INFO "Made executable: ${RESOLVED_BIN}"
    fi

    # Update symlink to the resolved binary
    [[ -L "$HOME/bin/$LINK_NAME" ]] && unlink "$HOME/bin/$LINK_NAME"
    ln -sf "$RESOLVED_BIN" "$HOME/bin/$LINK_NAME"
    echo "downloaded $LINK_NAME → $RESOLVED_BIN"
  else
    RESOLVED_BIN="$DEST_DIR/$PATH_TO_BIN"
    # Ensure executable even on already-present binaries
    if [[ -f "$RESOLVED_BIN" && ! -x "$RESOLVED_BIN" ]]; then
      chmod +x "$RESOLVED_BIN" || { rm -f "$tmp_tgz" || true; log ERROR "Failed to chmod +x ${RESOLVED_BIN}"; exit 1; }
      log INFO "Made executable: ${RESOLVED_BIN}"
    else
      log INFO "Bin already executable: ${RESOLVED_BIN}...nothing to do"
    fi
    # Keep symlink fresh
    [[ -L "$HOME/bin/$LINK_NAME" ]] && unlink "$HOME/bin/$LINK_NAME"
    ln -sf "$RESOLVED_BIN" "$HOME/bin/$LINK_NAME"
  fi

  # done with download temp
  rm -f "$tmp_tgz" || true

  # ---------------- dependency checks (optional per YAML) -------------------
  # Gather declared deps for this link_name (zero or more) safely via --arg.
  mapfile -t declared_deps < <(
    yq -r --arg ln "$LINK_NAME" \
      '((.binary_gz_tar_balls // .gz_tar_balls // [])[]
        | select(.link_name==$ln)
        | (.ldd_dependencies // []))[]?' \
      "$SCRIPT_DIR/install_from_http.yaml" 2>/dev/null || true
  )

  missing_declared=()
  if (( ${#declared_deps[@]} > 0 )); then
    log INFO "Checking declared runtime libraries for ${LINK_NAME}..."
    for dep in "${declared_deps[@]}"; do
      if ! _lib_present "$dep"; then
        missing_declared+=( "$dep" )
      fi
    done
    (( ${#missing_declared[@]} == 0 )) && log INFO "All declared libraries for ${LINK_NAME} are present."
  fi

  # ldd cross-check (only for dynamic ELF)
  ldd_miss=()
  if command -v ldd >/dev/null 2>&1; then
    if [[ -x "$RESOLVED_BIN" ]]; then
      if file "$RESOLVED_BIN" | grep -qiE 'ELF .* (dynamically linked|shared object)'; then
        mapfile -t ldd_miss < <( ldd "$RESOLVED_BIN" 2>/dev/null | awk '/=> not found/ {print $1}' || true )
        (( ${#ldd_miss[@]} == 0 )) && log INFO "ldd shows no missing libs for ${LINK_NAME}."
      else
        log INFO "Skipping ldd for ${LINK_NAME} (not dynamic ELF)."
      fi
    else
      log ERROR "Binary not executable for ldd check: ${RESOLVED_BIN}...bailing out"
      exit 1
    fi
  fi

  # Combine and de-duplicate missing libs (prefer declared token as display)
  declare -A _uniq=()
  for d in "${missing_declared[@]}"; do
    _uniq["$(_canon_lib "$d")"]="$d"
  done
  for d in "${ldd_miss[@]}"; do
    k="$(_canon_lib "$d")"
    [[ -n "${_uniq[$k]:-}" ]] || _uniq["$k"]="$d"
  done

  if (( ${#_uniq[@]} > 0 )); then
    unique_list=()
    for k in "${!_uniq[@]}"; do
      unique_list+=( "${_uniq[$k]}" )
    done
    log ERROR "Missing libraries for ${LINK_NAME}:"
    _pp_list "${unique_list[@]}"
    overall_missing=$(( overall_missing + ${#unique_list[@]} ))
    missing_report+=$'\n'"[${LINK_NAME}] Missing:"$'\n'"$(_pp_list "${unique_list[@]}")"
  fi

  unset missing_declared ldd_miss _uniq unique_list RESOLVED_BIN
done < "$_list_file"

if (( overall_missing > 0 )); then
  echo "---------------------------------------------------------------------------" >&2
  log ERROR "Detected ${overall_missing} missing library requirement(s) across one or more artifacts."
  [[ -n "$missing_report" ]] && printf "%s\n" "$missing_report" >&2
  echo "---------------------------------------------------------------------------" >&2
  echo "Hints:" >&2
  echo "  - Install the matching runtime libraries (Arch: pacman, Debian/Ubuntu: apt-get, RHEL/Fedora: dnf)." >&2
  echo "  - Library names are sonames; packages may have similar names (e.g., libxml2)." >&2
  exit 1
fi

log INFO "✅ Successfully installed software from http(s)"
exit 0

