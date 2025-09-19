#!/bin/bash
set -euo pipefail

# --- Source section ---
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
source "${SCRIPT_DIR}/_utils.sh"

log INFO "Now executing $(basename "${0}")"

# --- Global variables check ---
# : "${XXX:?must be set}"
# : "${APP_XXX:?must be set}"

# --- Hard prerequisites ---
check_commands_installed yq mkdir test ln curl sudo tar || {
   log ERROR "❌ Missing required commands." >&2
   exit 1
}

if ! [ -f "$SCRIPT_DIR/install_from_http.yaml" ]; then
   log ERROR "cannot find mandantory file: $SCRIPT_DIR/install_from_http.yaml...bailing out"
   exit 1
fi

# --- Main role logic ---

log INFO "Installing software from http(s)"

mkdir -p "$HOME/bin"

# installing gzip tar balls from http
yq -r '.gz_tar_balls[] | "\(.link_name) \(.extract_dir) \(.path_to_bin) \(.download_url)"' "$SCRIPT_DIR/install_from_http.yaml" | while read -r LINK_NAME EXTRACT_DIR PATH_TO_BIN DOWNLOAD_URL; do
   DEST_DIR="$HOME/bin/$LINK_NAME-versions/$EXTRACT_DIR"
   if ! test -f "$DEST_DIR/$PATH_TO_BIN"; then
      mkdir -p "$DEST_DIR"
      # download and put the archives content to a new top-level dir
      # Hint: the --strip-components=1 option removes the top-level directory from the file paths
      curl -L "$DOWNLOAD_URL" | tar -xz --strip-components=1 -C "$DEST_DIR"
      
      # force re-creation of link
      test -L "$HOME/bin/$LINK_NAME" && unlink "$HOME/bin/$LINK_NAME"
      ln -sf "$DEST_DIR/$PATH_TO_BIN" "$HOME/bin/$LINK_NAME"
      
      echo "downloaded binary $LINK_NAME, installed under $HOME/bin/$LINK_NAME linking to $DEST_DIR/$PATH_TO_BIN"
   fi
done 

# --- return 0 if OK ---
log INFO "✅ Successfully installed software from http(s)"
exit 0
