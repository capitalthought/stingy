#!/usr/bin/env bash
# stingy-guard: Pre-tool-use hook that checks for token-wasteful patterns
# Returns exit 0 (allow) or exit 2 (block with message)
#
# Environment variables set by Claude Code:
#   TOOL_NAME - the tool being called
#   TOOL_INPUT - JSON of the tool parameters

set -euo pipefail

TOOL="${TOOL_NAME:-}"
INPUT="${TOOL_INPUT:-}"

# Helper: block with a message
block() {
  echo "BLOCKED by stingy-guard: $1" >&2
  echo "" >&2
  echo "💰 Token-saving suggestion: $2" >&2
  exit 2
}

# Helper: warn but allow
warn() {
  echo "⚠️  stingy-guard: $1" >&2
  exit 0
}

case "$TOOL" in
  Read)
    # Check if reading a whole file without offset/limit on a large file
    file_path=$(echo "$INPUT" | python3 -c "import json,sys; d=json.load(sys.stdin); print(d.get('file_path',''))" 2>/dev/null || echo "")
    has_limit=$(echo "$INPUT" | python3 -c "import json,sys; d=json.load(sys.stdin); print('yes' if d.get('limit') else 'no')" 2>/dev/null || echo "no")

    if [ -n "$file_path" ] && [ -f "$file_path" ] && [ "$has_limit" = "no" ]; then
      lines=$(wc -l < "$file_path" 2>/dev/null | tr -d ' ')
      if [ "$lines" -gt 500 ] 2>/dev/null; then
        warn "Reading $lines-line file without offset/limit. Consider: Read with offset/limit, or Grep to find the relevant section first. (~$((lines * 10)) tokens)"
      fi
    fi
    ;;

  Bash)
    cmd=$(echo "$INPUT" | python3 -c "import json,sys; d=json.load(sys.stdin); print(d.get('command',''))" 2>/dev/null || echo "")

    # Detect cat/head/tail when Read should be used
    case "$cmd" in
      cat\ *|head\ *|tail\ *)
        warn "Use the Read tool instead of '$cmd'. Read is formatted better and cheaper."
        ;;
      grep\ *|rg\ *)
        warn "Use the Grep tool instead of shell grep/rg. Dedicated tools have lower overhead."
        ;;
      find\ *)
        warn "Use the Glob tool instead of 'find'. It's faster and cheaper."
        ;;
    esac
    ;;

  Agent)
    # Warn on agent spawns — each one duplicates the full context
    warn "Agent spawn detected. Each agent duplicates ~15-30K tokens of system context. Is a direct Grep/Read enough instead?"
    ;;

  WebSearch)
    warn "Web search uses significant tokens for results. Make sure you can't answer this from local files or existing knowledge."
    ;;
esac

# Default: allow
exit 0
