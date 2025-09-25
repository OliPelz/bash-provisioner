# tests/test_install_libs.sh
#!/usr/bin/env bash
# shUnit2 suite: library installs (libxml2)
set -u

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
ROOT_DIR="$(cd "${SCRIPT_DIR}/.." && pwd)"

# Require shunit2 in PATH
command -v shunit2 >/dev/null 2>&1 || { echo "shunit2 not found in PATH" >&2; exit 1; }

# Optional prefix for your patched shunit2 verbose output
export SHUNIT_TEST_PREFIX='TEST: '

# Minimal, portable presence check for a runtime .so
_lib_present() {
  local so_pat="$1"  # e.g., libxml2.so or libxml2.so.2
  if command -v ldconfig >/dev/null 2>&1; then
    ldconfig -p 2>/dev/null | awk '{print $1}' | grep -q -E "^${so_pat}(\.|$)" && return 0
  fi
  # Fallback paths
  compgen -G "/lib*/${so_pat}*" >/dev/null && return 0
  compgen -G "/usr/lib*/${so_pat}*" >/dev/null && return 0
  compgen -G "/usr/local/lib*/${so_pat}*" >/dev/null && return 0
  return 1
}

test_libxml2_runtime_present() {
  echo "Running TEST: test_libxml2_runtime_present"
  # Accept either exact soname (.so.2) or unversioned linker name (.so), depending on distro
  if _lib_present "libxml2.so.2" || _lib_present "libxml2.so"; then
    assertTrue "libxml2 runtime library should be present" "true"
  else
    # Print a small diagnostic to help debugging when it fails
    echo "[DEBUG] ldconfig present? $(command -v ldconfig >/dev/null 2>&1 && echo yes || echo no)"
    command -v ldconfig >/dev/null 2>&1 && ldconfig -p | grep -i libxml2 || true
    ls -l /lib*/*xml2*.so* /usr/lib*/*xml2*.so* /usr/local/lib*/*xml2*.so* 2>/dev/null || true
    assertTrue "libxml2 runtime library should be present (libxml2.so or libxml2.so.2)" "false"
  fi
}

# Load shUnit2
. "$(command -v shunit2)"

