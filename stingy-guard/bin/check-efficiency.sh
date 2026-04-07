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

# Session-scoped spawn tracking directory (keyed by parent PID so each
# Claude Code session gets its own counters).
SPAWN_DIR="/tmp/stingy-guard-${PPID:-0}"
mkdir -p "$SPAWN_DIR" 2>/dev/null || true

# Helper: warn but allow (always exit 0)
warn() {
  echo "⚠️  stingy-guard: $1" >&2
  exit 0
}

# Helper: increment spawn count for a tool and return the NEW count.
# First call returns 1, second returns 2, etc.
bump_spawn_count() {
  local tool_key="$1"
  local count_file="$SPAWN_DIR/$tool_key"
  local prev=0
  if [ -f "$count_file" ]; then
    prev=$(cat "$count_file" 2>/dev/null || echo 0)
  fi
  local next=$(( prev + 1 ))
  echo "$next" > "$count_file" 2>/dev/null || true
  echo "$next"
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

    # Detect commands that have cheaper dedicated tool equivalents.
    # Check anywhere in the command string (not just prefix) to catch flags,
    # pipes, and subshells like "cat -n file", "git log | grep foo", etc.
    first_word="${cmd%% *}"
    case "$first_word" in
      cat|head|tail)
        warn "Use the Read tool instead of '$first_word'. Read is formatted better and cheaper." ;;
      grep|rg)
        warn "Use the Grep tool instead of shell grep/rg. Dedicated tools have lower overhead." ;;
      find)
        warn "Use the Glob tool instead of 'find'. It's faster and cheaper." ;;
      *)
        # Also check after pipes: "git log | grep foo"
        if echo "$cmd" | grep -qE '\|\s*(cat|head|tail)\b'; then
          warn "Piped to cat/head/tail — consider using Read with offset/limit instead."
        elif echo "$cmd" | grep -qE '\|\s*(grep|rg)\b'; then
          warn "Piped to grep/rg — consider using the Grep tool instead."
        fi
        ;;
    esac
    ;;

  Agent)
    count=$(bump_spawn_count "Agent")
    if [ "$count" -ge 2 ] 2>/dev/null; then
      warn "Agent spawn #$count this session. Each agent duplicates ~15-30K tokens of system context. Is a direct Grep/Read enough instead?"
    fi
    ;;

  WebSearch)
    count=$(bump_spawn_count "WebSearch")
    if [ "$count" -ge 2 ] 2>/dev/null; then
      warn "Web search #$count this session. Significant token cost per search. Make sure you can't answer this from local files or existing knowledge."
    fi
    ;;
esac

# Default: always allow
exit 0
