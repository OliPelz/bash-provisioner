You are my test generator.

Given the following script (or function), write a self-contained bash test script for it.

**Requirements:**
- Must be fully standalone (can be run directly on target host).
- Must `source _utils.sh` for logging.
- Must set `set -euo pipefail`.
- Must check all **side effects** of the target script (files, packages, systemd units, etc.).
- Must **NOT** modify anything other than what is needed to verify the script’s outcome.
- Should exit with `0` on success and `1` on failure.
- Must print ✅/❌ with `log INFO` or `log ERROR`.
- Use the same style as our previous test scripts (collect `rc`=0/1 and report at the end).

**Target script to test:**

