---
name: stingy-guard
description: |
  Toggle the token efficiency guard hook on or off. When active, it monitors every
  tool call and warns about token-wasteful patterns: reading entire large files,
  using Bash instead of dedicated tools, unnecessary agent spawns, and more.
  Use when: "stingy guard", "guard on", "guard off", "watch my tokens",
  "monitor efficiency", "enable token guard", "disable token guard".
allowed-tools:
  - Bash
  - Read
  - Write
  - Edit
  - AskUserQuestion
---

# /stingy-guard — Token Efficiency Guard

Toggle the pre-tool-use hook that monitors every tool call for token waste.

## What It Does

When active, the guard intercepts tool calls BEFORE they execute and warns about:

- **Read** of files >500 lines without offset/limit
- **Bash** running `cat`, `grep`, `find` when dedicated tools are cheaper
- **Agent** spawns (each duplicates ~15-30K tokens of system context)
- **WebSearch** when local knowledge might suffice

The guard only WARNS — it doesn't block. You see the warning and decide whether
to proceed.

## Step 1: Check Current Status

```bash
STINGY_DIR="$(cd "$(dirname "$(readlink -f "${BASH_SOURCE[0]}" 2>/dev/null || echo "$0")")" && cd ../.. && pwd)"
HOOK_SCRIPT="$STINGY_DIR/stingy-guard/bin/check-efficiency.sh"

if [ -f ~/.claude/settings.json ]; then
  if grep -q "check-efficiency" ~/.claude/settings.json 2>/dev/null; then
    echo "GUARD: ACTIVE"
  else
    echo "GUARD: INACTIVE"
  fi
else
  echo "GUARD: INACTIVE (no settings.json)"
fi
echo "HOOK_SCRIPT: $HOOK_SCRIPT"
```

## Step 2: Toggle

Ask the user:

> Token guard is currently [ACTIVE/INACTIVE].
>
> A) Turn ON — warns before wasteful tool calls
> B) Turn OFF — no monitoring
> C) Show me what it checks

If A (enable):
The hook needs to be added to `~/.claude/settings.json` under the `hooks` key.
Read the current settings.json, add the PreToolUse hook, and write it back.

The hook entry should look like:
```json
{
  "hooks": {
    "PreToolUse": [
      {
        "matcher": "*",
        "hooks": [
          {
            "type": "command",
            "command": "TOOL_NAME=$TOOL_NAME TOOL_INPUT=$TOOL_INPUT /path/to/stingy/stingy-guard/bin/check-efficiency.sh"
          }
        ]
      }
    ]
  }
}
```

Replace `/path/to/stingy` with the actual path to the stingy repo.

**Important:** Merge with existing hooks — don't overwrite them.

If B (disable):
Remove the stingy-guard hook entry from settings.json. Leave other hooks intact.

If C (show):
List what the guard checks and explain each one.

## Rules

- Always back up settings.json before modifying: `cp ~/.claude/settings.json ~/.claude/settings.json.bak`
- Merge hooks — never overwrite existing hooks from other tools
- The guard should be fast (<100ms) — it runs on every tool call
- Warnings go to stderr so they don't interfere with tool output
