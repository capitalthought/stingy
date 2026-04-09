#!/usr/bin/env bash
# toggle-hook.sh — safely add or remove the stingy-guard hook from settings.json
# Usage: toggle-hook.sh on|off|status
set -uo pipefail

SETTINGS="$HOME/.claude/settings.json"
STINGY_DIR="$(cd "$(dirname "$0")/../.." && pwd)"
HOOK_CMD="$STINGY_DIR/stingy-guard/bin/check-efficiency.sh"

if ! [ -f "$SETTINGS" ]; then
  echo "Error: $SETTINGS not found" >&2
  exit 1
fi

# Check if jq is available (preferred) or fall back to python3
if command -v jq >/dev/null 2>&1; then
  JSON_TOOL="jq"
elif command -v python3 >/dev/null 2>&1; then
  JSON_TOOL="python3"
else
  echo "Error: jq or python3 required to modify settings.json" >&2
  exit 1
fi

is_installed() {
  grep -q "check-efficiency.sh" "$SETTINGS" 2>/dev/null
}

case "${1:-status}" in
  on)
    if is_installed; then
      echo "stingy-guard hook is already installed."
      exit 0
    fi

    # Back up
    cp "$SETTINGS" "$SETTINGS.bak.$(date +%s)"
    echo "Backed up settings.json"

    if [ "$JSON_TOOL" = "jq" ]; then
      # Use jq to safely merge the hook
      jq --arg cmd "$HOOK_CMD" '
        .hooks //= {} |
        .hooks.PreToolUse //= [] |
        .hooks.PreToolUse += [{
          "matcher": "*",
          "hooks": [{
            "type": "command",
            "command": $cmd
          }]
        }]
      ' "$SETTINGS" > "$SETTINGS.tmp" && mv "$SETTINGS.tmp" "$SETTINGS"
    else
      python3 -c "
import json, sys
with open('$SETTINGS') as f:
    data = json.load(f)
data.setdefault('hooks', {})
data['hooks'].setdefault('PreToolUse', [])
data['hooks']['PreToolUse'].append({
    'matcher': '*',
    'hooks': [{'type': 'command', 'command': '$HOOK_CMD'}]
})
with open('$SETTINGS', 'w') as f:
    json.dump(data, f, indent=2)
"
    fi

    # Validate
    if python3 -c "import json; json.load(open('$SETTINGS'))" 2>/dev/null || jq empty "$SETTINGS" 2>/dev/null; then
      echo "✅ stingy-guard hook installed. Restart Claude Code to activate."
    else
      echo "❌ JSON validation failed! Restoring backup..." >&2
      # shellcheck disable=SC2012
      cp "$(ls -t "$SETTINGS".bak.* | head -1)" "$SETTINGS"
      exit 1
    fi
    ;;

  off)
    if ! is_installed; then
      echo "stingy-guard hook is not installed."
      exit 0
    fi

    cp "$SETTINGS" "$SETTINGS.bak.$(date +%s)"
    echo "Backed up settings.json"

    if [ "$JSON_TOOL" = "jq" ]; then
      jq --arg cmd "$HOOK_CMD" '
        if .hooks.PreToolUse then
          .hooks.PreToolUse |= map(
            .hooks |= map(select(.command != $cmd)) |
            select(.hooks | length > 0)
          ) |
          if .hooks.PreToolUse | length == 0 then del(.hooks.PreToolUse) else . end
        else . end
      ' "$SETTINGS" > "$SETTINGS.tmp" && mv "$SETTINGS.tmp" "$SETTINGS"
    else
      python3 -c "
import json
with open('$SETTINGS') as f:
    data = json.load(f)
hooks = data.get('hooks', {}).get('PreToolUse', [])
data['hooks']['PreToolUse'] = [
    h for h in hooks
    if not any('check-efficiency.sh' in sub.get('command', '') for sub in h.get('hooks', []))
]
if not data['hooks']['PreToolUse']:
    del data['hooks']['PreToolUse']
with open('$SETTINGS', 'w') as f:
    json.dump(data, f, indent=2)
"
    fi

    # Validate
    if python3 -c "import json; json.load(open('$SETTINGS'))" 2>/dev/null || jq empty "$SETTINGS" 2>/dev/null; then
      echo "✅ stingy-guard hook removed. Restart Claude Code to take effect."
    else
      echo "❌ JSON validation failed! Restoring backup..." >&2
      # shellcheck disable=SC2012
      cp "$(ls -t "$SETTINGS".bak.* | head -1)" "$SETTINGS"
      exit 1
    fi
    ;;

  status)
    if is_installed; then
      echo "stingy-guard: ACTIVE"
    else
      echo "stingy-guard: INACTIVE"
    fi
    ;;

  *)
    echo "Usage: toggle-hook.sh on|off|status" >&2
    exit 1
    ;;
esac
