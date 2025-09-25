#!/usr/bin/env bash
set -Eeuo pipefail
#set -x

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
source "${SCRIPT_DIR}/_utils.sh"

log INFO "Now executing $(basename "${0}")"

# we need this for our custom yq
export PATH=$HOME/bin/:$PATH

check_commands_installed file ldconfig ldd yq mkdir test ln pcurl_wrapper sudo tar awk grep sed || {
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
    # Extract first column (soname) and look for exact or versioned matches
    if ldconfig -p 2>/dev/null | awk '{print $1}' | grep -Eq "^${so_pat}(\.|$)"; then
      return 0
    fi
  fi

  # 2) Fallback: scan common library paths (covers systems where ldconfig is missing/not cached)
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

log INFO "Installing software from http(s)"
mkdir -p "$HOME/bin"

overall_missing=0
missing_report=""

# Keep your existing yq stream intact (space-separated). We'll query deps per item inside the loop.
yq -r '.binary_gz_tar_balls[] | "\(.link_name) \(.extract_dir) \(.path_to_bin) \(.download_url)"' \
  "$SCRIPT_DIR/install_from_http.yaml" |
while read -r LINK_NAME EXTRACT_DIR PATH_TO_BIN DOWNLOAD_URL; do
   DEST_DIR="$HOME/bin/$LINK_NAME-versions/$EXTRACT_DIR"

   if [[ ! -f "$DEST_DIR/$PATH_TO_BIN" ]]; then
      mkdir -p "$DEST_DIR"
      pcurl_wrapper -L "$DOWNLOAD_URL" | tar -xz -C "$DEST_DIR"
      [[ -L "$HOME/bin/$LINK_NAME" ]] && unlink "$HOME/bin/$LINK_NAME"
      ln -sf "$DEST_DIR/$PATH_TO_BIN" "$HOME/bin/$LINK_NAME"
      echo "downloaded $LINK_NAME → $DEST_DIR/$PATH_TO_BIN"
   fi

   # ---------------- dependency checks (optional per YAML) -------------------
   # Gather declared deps for this link_name (zero or more).
   mapfile -t declared_deps < <( yq -r \
     ".binary_gz_tar_balls[] | select(.link_name==\"${LINK_NAME}\") | (.ldd_dependencies // [])[]?" \
     "$SCRIPT_DIR/install_from_http.yaml" \
     2>/dev/null || true )

   # 1) Check declared deps via ldconfig/filesystem
   if (( ${#declared_deps[@]} > 0 )); then
     log INFO "Checking declared runtime libraries for ${LINK_NAME}..."
     missing_declared=()
     for dep in "${declared_deps[@]}"; do
       if ! _lib_present "$dep"; then
         missing_declared+=( "$dep" )
       fi
     done
     if (( ${#missing_declared[@]} > 0 )); then
       log ERROR "Missing libraries for ${LINK_NAME}:"
       _pp_list "${missing_declared[@]}"
       overall_missing=$(( overall_missing + ${#missing_declared[@]} ))
       missing_report+=$'\n'"[${LINK_NAME}] Missing (declared):"$'\n'"$(_pp_list "${missing_declared[@]}")"
     else
       log INFO "All declared libraries for ${LINK_NAME} are present."
     fi
   fi

   # 2) Cross-check with ldd (best-effort; may be noisy if binary is musl-static or not a dynamic ELF)
   if command -v ldd >/dev/null 2>&1; then
     if [[ -x "$DEST_DIR/$PATH_TO_BIN" ]]; then
       # Only run on dynamic ELF; ignore scripts and static/musl messages gracefully.
       if file "$DEST_DIR/$PATH_TO_BIN" | grep -qiE 'ELF .* (dynamically linked|shared object)'; then
         # Capture "=> not found" entries
         mapfile -t ldd_miss < <( ldd "$DEST_DIR/$PATH_TO_BIN" 2>/dev/null | awk '/=> not found/ {print $1}' || true )
         if (( ${#ldd_miss[@]} > 0 )); then
           log ERROR "ldd reports missing libraries for ${LINK_NAME}:"
           _pp_list "${ldd_miss[@]}"
           overall_missing=$(( overall_missing + ${#ldd_miss[@]} ))
           missing_report+=$'\n'"[${LINK_NAME}] Missing (ldd):"$'\n'"$(_pp_list "${ldd_miss[@]}")"
         else
           log INFO "ldd shows no missing libs for ${LINK_NAME}."
         fi
       else
         log ERROR "cannot ldd check for ${LINK_NAME}...bailing out"
         exit 1
       fi
     else
       log ERROR "Binary not executable for ldd check: ${DEST_DIR}/${PATH_TO_BIN}...bailing out"
       exit 1
     fi
   fi

done

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

