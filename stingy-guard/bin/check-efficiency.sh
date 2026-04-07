#!/usr/bin/env bash
# stingy-guard: Pre-tool-use hook that checks for token-wasteful patterns
# Returns exit 0 (allow). Warnings go to stderr.
# Must NEVER exit non-zero accidentally — that could block tool calls.
#
# Environment variables set by Claude Code:
#   TOOL_NAME - the tool being called
#   TOOL_INPUT - JSON of the tool parameters

# No set -e: a parse failure must NOT block tool calls. Default to allow.
set -uo pipefail

TOOL="${TOOL_NAME:-}"
INPUT="${TOOL_INPUT:-}"

# Helper: warn but allow (always exit 0)
warn() {
  echo "⚠️  stingy-guard: $1" >&2
  exit 0
}

# Extract a JSON string field using jq if available, else bash heuristics
json_field() {
  local field="$1"
  if command -v jq >/dev/null 2>&1; then
    printf '%s' "$INPUT" | jq -r ".$field // empty" 2>/dev/null || echo ""
  else
    # Fallback: rough bash extraction for simple string fields
    printf '%s' "$INPUT" | sed -n "s/.*\"$field\"[[:space:]]*:[[:space:]]*\"\([^\"]*\)\".*/\1/p" 2>/dev/null | head -1
  fi
}

case "$TOOL" in
  Read)
    # Check if reading a whole file without offset/limit on a large file
    file_path=$(json_field "file_path")
    has_limit=$(printf '%s' "$INPUT" | grep -q '"limit"' && echo "yes" || echo "no")

    if [ -n "$file_path" ] && [ -f "$file_path" ] && [ "$has_limit" = "no" ]; then
      lines=$(wc -l < "$file_path" 2>/dev/null | tr -d ' ')
      if [ "${lines:-0}" -gt 500 ] 2>/dev/null; then
        warn "Reading $lines-line file without offset/limit. Consider: Read with offset/limit, or Grep to find the relevant section first. (~$((lines * 10)) tokens)"
      fi
    fi
    ;;

  Bash)
    # Extract command with bash heuristic (avoid python3/jq overhead for simple check)
    cmd=$(printf '%s' "$INPUT" | sed -n 's/.*"command"[[:space:]]*:[[:space:]]*"\([^"]*\)".*/\1/p' 2>/dev/null | head -1)

    # Detect cat/head/tail when Read should be used
    case "$cmd" in
      cat\ *|head\ *|tail\ *)
        warn "Use the Read tool instead of '${cmd%% *}'. Read is formatted better and cheaper."
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
    warn "Agent spawn detected. Each agent duplicates ~15-30K tokens of system context. Is a direct Grep/Read enough instead?"
    ;;

  WebSearch)
    warn "Web search uses significant tokens for results. Make sure you can't answer this from local files or existing knowledge."
    ;;
esac

# Default: always allow
exit 0
