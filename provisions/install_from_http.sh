#!/usr/bin/env bash
set -Eeuo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
source "${SCRIPT_DIR}/_utils.sh"

log INFO "Now executing $(basename "${0}")"

check_commands_installed yq mkdir test ln curl sudo tar || {
   log ERROR "❌ Missing required commands."; exit 1; }

if [[ ! -f "$SCRIPT_DIR/install_from_http.yaml" ]]; then
   log ERROR "cannot find mandatory file: $SCRIPT_DIR/install_from_http.yaml...bailing out"
   exit 1
fi

log INFO "Installing software from http(s)"
mkdir -p "$HOME/bin"

yq -r '.gz_tar_balls[] | "\(.link_name) \(.extract_dir) \(.path_to_bin) \(.download_url)"' \
  "$SCRIPT_DIR/install_from_http.yaml" |
while read -r LINK_NAME EXTRACT_DIR PATH_TO_BIN DOWNLOAD_URL; do
   DEST_DIR="$HOME/bin/$LINK_NAME-versions/$EXTRACT_DIR"
   if [[ ! -f "$DEST_DIR/$PATH_TO_BIN" ]]; then
      mkdir -p "$DEST_DIR"
      curl -L ${DISABLE_IPV6:+--ipv4} "$DOWNLOAD_URL" | tar -xz --strip-components=1 -C "$DEST_DIR"
      [[ -L "$HOME/bin/$LINK_NAME" ]] && unlink "$HOME/bin/$LINK_NAME"
      ln -sf "$DEST_DIR/$PATH_TO_BIN" "$HOME/bin/$LINK_NAME"
      echo "downloaded $LINK_NAME → $DEST_DIR/$PATH_TO_BIN"
   fi
done

log INFO "✅ Successfully installed software from http(s)"
exit 0

