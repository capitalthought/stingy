#!/usr/bin/env bash
# Integration tests for stingy-guard/bin/check-efficiency.sh
# Usage: ./tests/test-guard-hook.sh

set -uo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
HOOK="$SCRIPT_DIR/../stingy-guard/bin/check-efficiency.sh"

if [ ! -x "$HOOK" ]; then
  echo "ERROR: Hook not found or not executable: $HOOK"
  exit 1
fi

pass=0
fail=0

# Temp dir for large file, stderr captures, and spawn tracking isolation.
TMPDIR_TEST="$(mktemp -d)"
LARGE_FILE="$TMPDIR_TEST/large-file.txt"
STDERR_CAPTURE="$TMPDIR_TEST/stderr.txt"

# The hook uses SPAWN_DIR="/tmp/stingy-guard-${PPID:-0}".
# When the hook is invoked via command substitution, PPID in the hook equals
# the PID of the command-substitution subshell — which varies per call and
# defeats spawn counting.  Instead we capture output to a temp file so the
# hook is a direct child of this script; its PPID will be $$.
SPAWN_DIR="/tmp/stingy-guard-$$"

# Generate a 501-line file
python3 -c "print('\n'.join(['line'] * 501))" > "$LARGE_FILE"

cleanup() {
  rm -rf "$TMPDIR_TEST"
  rm -rf "$SPAWN_DIR"
}
trap cleanup EXIT

# Reset spawn tracking for this test run.
rm -rf "$SPAWN_DIR"
mkdir -p "$SPAWN_DIR"

# -----------------------------------------------------------------------
# run_hook TOOL_NAME TOOL_INPUT
#   Runs the hook as a direct child (no command substitution) so PPID is
#   stable.  Captures stderr to $STDERR_CAPTURE, stdout is discarded.
#   Sets global HOOK_EXIT to the exit code.
# -----------------------------------------------------------------------
HOOK_EXIT=0
run_hook() {
  local tool_name="$1"
  local tool_input="$2"
  TOOL_NAME="$tool_name" TOOL_INPUT="$tool_input" \
    bash "$HOOK" >"$TMPDIR_TEST/stdout.txt" 2>"$STDERR_CAPTURE"
  HOOK_EXIT=$?
}

# -----------------------------------------------------------------------
# test_case NAME EXPECT_WARN TOOL_NAME TOOL_INPUT
#   EXPECT_WARN: "warn"    -> stderr must be non-empty
#                "no-warn" -> stderr must be empty
#   Exit code is always asserted to be 0.
# -----------------------------------------------------------------------
test_case() {
  local name="$1"
  local expect="$2"
  local tool_name="$3"
  local tool_input="$4"

  run_hook "$tool_name" "$tool_input"

  # Filter out any "PPID: readonly" noise from the outer shell (shouldn't
  # appear now that we don't try to override PPID, but guard just in case).
  local stderr_out
  stderr_out=$(grep -v "PPID: readonly" "$STDERR_CAPTURE" 2>/dev/null || true)

  # Assert exit 0
  if [ "$HOOK_EXIT" -ne 0 ]; then
    echo "❌ FAIL [$name]: expected exit 0, got $HOOK_EXIT"
    (( fail++ )) || true
    return
  fi

  if [ "$expect" = "warn" ]; then
    if [ -n "$stderr_out" ]; then
      echo "✅ PASS [$name]: got expected warning"
      (( pass++ )) || true
    else
      echo "❌ FAIL [$name]: expected a warning on stderr but got none"
      (( fail++ )) || true
    fi
  else
    if [ -z "$stderr_out" ]; then
      echo "✅ PASS [$name]: no warning (correct)"
      (( pass++ )) || true
    else
      echo "❌ FAIL [$name]: expected NO warning but got: $stderr_out"
      (( fail++ )) || true
    fi
  fi
}

# -----------------------------------------------------------------------
# 1. Read large file — no limit → should warn
# -----------------------------------------------------------------------
test_case \
  "Read large file without limit" \
  "warn" \
  "Read" \
  "{\"file_path\": \"$LARGE_FILE\"}"

# -----------------------------------------------------------------------
# 2. Read large file with limit → should NOT warn
# -----------------------------------------------------------------------
test_case \
  "Read large file with limit" \
  "no-warn" \
  "Read" \
  "{\"file_path\": \"$LARGE_FILE\", \"limit\": 50}"

# -----------------------------------------------------------------------
# 3. Bash cat — should warn about Read tool
# -----------------------------------------------------------------------
test_case \
  "Bash cat warning" \
  "warn" \
  "Bash" \
  '{"command": "cat foo.txt"}'

# -----------------------------------------------------------------------
# 4. Bash grep — should warn about Grep tool
# -----------------------------------------------------------------------
test_case \
  "Bash grep warning" \
  "warn" \
  "Bash" \
  '{"command": "grep pattern file.txt"}'

# -----------------------------------------------------------------------
# 5. Bash find — should warn about Glob
# -----------------------------------------------------------------------
test_case \
  "Bash find warning" \
  "warn" \
  "Bash" \
  '{"command": "find . -name '\''*.md'\''"}'

# -----------------------------------------------------------------------
# 6. Bash pipe with grep — should warn about piped grep
# -----------------------------------------------------------------------
test_case \
  "Bash pipe to grep" \
  "warn" \
  "Bash" \
  '{"command": "git log | grep foo"}'

# -----------------------------------------------------------------------
# 7a. Agent spawn #1 — first call, no warning expected
# The hook will write count=1 to $SPAWN_DIR/Agent; count < 2 → no warn.
# -----------------------------------------------------------------------
test_case \
  "Agent spawn #1 (no warning)" \
  "no-warn" \
  "Agent" \
  '{"prompt": "do something"}'

# -----------------------------------------------------------------------
# 7b. Agent spawn #2 — count already=1 from above, hook increments to 2 → warn
# -----------------------------------------------------------------------
test_case \
  "Agent spawn #2 (warning)" \
  "warn" \
  "Agent" \
  '{"prompt": "do something else"}'

# -----------------------------------------------------------------------
# 8. Normal tool (Edit) — should produce no warning
# -----------------------------------------------------------------------
test_case \
  "Edit tool — no warning" \
  "no-warn" \
  "Edit" \
  '{"file_path": "/tmp/foo.txt", "old_string": "a", "new_string": "b"}'

# -----------------------------------------------------------------------
# 9. Exit code verification — all dangerous cases must exit 0
#    (each test_case already checks this; this block is an explicit
#    belt-and-suspenders pass over key scenarios)
# -----------------------------------------------------------------------
exit_check_pass=true
for scenario in \
  "Read|{\"file_path\": \"$LARGE_FILE\"}" \
  "Bash|{\"command\": \"cat foo.txt\"}" \
  "Bash|{\"command\": \"grep x y\"}" \
  "Bash|{\"command\": \"find . -name '*.sh'\"}" \
  "Agent|{\"prompt\": \"x\"}"
do
  t="${scenario%%|*}"
  inp="${scenario#*|}"
  run_hook "$t" "$inp"
  if [ "$HOOK_EXIT" -ne 0 ]; then
    echo "❌ FAIL [exit-0 check for $t]: exit code was $HOOK_EXIT"
    exit_check_pass=false
    (( fail++ )) || true
  fi
done
if $exit_check_pass; then
  echo "✅ PASS [exit-0 checks]: all scenarios exited 0"
  (( pass++ )) || true
fi

# -----------------------------------------------------------------------
# Summary
# -----------------------------------------------------------------------
echo ""
echo "Results: $pass passed, $fail failed"
[ "$fail" -eq 0 ] || exit 1
