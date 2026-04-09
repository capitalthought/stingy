#!/usr/bin/env bash
# stingy session-start hook — nudge if maintenance is overdue
# Reads generated/maintenance.json and warns if >30 days since last run.
# Must never fail — always exit 0.

set -uo pipefail

# Find the stingy repo root (two levels up from this script)
STINGY_DIR="$(cd "$(dirname "$0")/../.." && pwd)"
MAINT_FILE="$STINGY_DIR/generated/maintenance.json"
INTERVAL_DAYS=30

# If maintenance.json doesn't exist, nudge immediately
if [ ! -f "$MAINT_FILE" ]; then
  echo "💰 stingy: Plugin maintenance has never been run. Run /stingy:maintenance to check for upstream pricing and model changes." >&2
  exit 0
fi

# Extract lastRun timestamp — try jq, fall back to bash
if command -v jq >/dev/null 2>&1; then
  last_run=$(jq -r '.lastRun // empty' "$MAINT_FILE" 2>/dev/null)
else
  last_run=$(sed -n 's/.*"lastRun"[[:space:]]*:[[:space:]]*"\([^"]*\)".*/\1/p' "$MAINT_FILE" 2>/dev/null | head -1)
fi

# If we can't parse it, nudge
if [ -z "${last_run:-}" ]; then
  echo "💰 stingy: Can't read maintenance timestamp. Run /stingy:maintenance to check for upstream changes." >&2
  exit 0
fi

# Calculate days since last run
if command -v python3 >/dev/null 2>&1; then
  days_ago=$(python3 -c "
from datetime import datetime, timezone
try:
    ts = datetime.fromisoformat('$last_run'.replace('Z','+00:00'))
    print(int((datetime.now(timezone.utc) - ts).total_seconds() / 86400))
except:
    print(-1)
" 2>/dev/null)
elif date --version >/dev/null 2>&1; then
  # GNU date
  last_epoch=$(date -d "$last_run" +%s 2>/dev/null || echo 0)
  now_epoch=$(date +%s)
  days_ago=$(( (now_epoch - last_epoch) / 86400 ))
else
  # macOS date
  last_epoch=$(date -jf "%Y-%m-%dT%H:%M:%SZ" "$last_run" +%s 2>/dev/null || date -jf "%Y-%m-%dT%H:%M:%S" "${last_run%Z}" +%s 2>/dev/null || echo 0)
  now_epoch=$(date +%s)
  days_ago=$(( (now_epoch - last_epoch) / 86400 ))
fi

if [ "${days_ago:-0}" -lt 0 ] 2>/dev/null; then
  # Parse failed
  exit 0
fi

if [ "$days_ago" -ge "$INTERVAL_DAYS" ] 2>/dev/null; then
  echo "💰 stingy: Plugin maintenance last run ${days_ago} days ago. Run /stingy:maintenance to check for upstream pricing and model changes." >&2
fi

exit 0
