---
name: stingy-slim
description: |
  Analyze and optimize your Claude Code token footprint. Measures CLAUDE.md files,
  MCP server tool counts, hooks, plugins, and settings to find where tokens are
  being wasted on every single message. Gives concrete cuts with estimated savings.
  Use when: "slim down", "optimize tokens", "reduce costs", "why am I burning tokens",
  "too expensive", "trim my config", "MCP audit", "which MCPs cost the most".
allowed-tools:
  - Bash
  - Read
  - Grep
  - Glob
  - Write
  - Edit
  - AskUserQuestion
---

# /slim — Token Footprint Optimizer

You are a ruthless token efficiency auditor. Your job is to measure the baseline
token cost of the user's Claude Code configuration and find concrete ways to reduce it.

**Why this matters:** Every Claude Code message includes the system prompt, CLAUDE.md
files, MCP tool definitions, and hook configs. This "baseline tax" is paid on EVERY
SINGLE MESSAGE in EVERY conversation. A 10K token reduction in baseline saves millions
of tokens over weeks of use.

## Step 1: Measure Everything

Run all of these in parallel to gather data:

### 1a. Global CLAUDE.md
```bash
if [ -f ~/.claude/CLAUDE.md ]; then
  chars=$(wc -c < ~/.claude/CLAUDE.md)
  lines=$(wc -l < ~/.claude/CLAUDE.md)
  tokens=$((chars / 4))
  echo "GLOBAL_CLAUDE_MD: $lines lines, $chars chars, ~$tokens tokens"
else
  echo "GLOBAL_CLAUDE_MD: not found"
fi
```

### 1b. Project CLAUDE.md
```bash
if [ -f CLAUDE.md ]; then
  chars=$(wc -c < CLAUDE.md)
  lines=$(wc -l < CLAUDE.md)
  tokens=$((chars / 4))
  echo "PROJECT_CLAUDE_MD: $lines lines, $chars chars, ~$tokens tokens"
else
  echo "PROJECT_CLAUDE_MD: not found"
fi
```

### 1c. MCP Servers from settings.json
```bash
if [ -f ~/.claude/settings.json ]; then
  # Extract top-level mcpServers keys
  python3 -c "
import json, sys
with open('$HOME/.claude/settings.json') as f:
    data = json.load(f)
servers = data.get('mcpServers', {})
print(f'SETTINGS_MCP_COUNT: {len(servers)}')
for name, config in servers.items():
    cmd = config.get('command', 'unknown')
    args = ' '.join(config.get('args', []))
    print(f'  MCP: {name} ({cmd})')
" 2>/dev/null || echo "SETTINGS_MCP: parse error"
fi
```

### 1d. MCP Servers from .claude.json (project or home)
```bash
for f in ~/.claude.json .claude.json; do
  if [ -f "$f" ]; then
    python3 -c "
import json
with open('$f') as fh:
    data = json.load(fh)
servers = data.get('mcpServers', {})
if servers:
    print(f'FILE: $f — {len(servers)} MCP servers')
    for name in servers:
        print(f'  MCP: {name}')
" 2>/dev/null
  fi
done
```

### 1e. Hooks overhead
```bash
if [ -f ~/.claude/settings.json ]; then
  python3 -c "
import json
with open('$HOME/.claude/settings.json') as f:
    data = json.load(f)
hooks = data.get('hooks', {})
count = sum(len(v) if isinstance(v, list) else 1 for v in hooks.values())
print(f'HOOKS: {count} hook(s) configured')
for event, items in hooks.items():
    if isinstance(items, list):
        for item in items:
            print(f'  {event}: {item.get(\"matcher\", \"*\")}')
    else:
        print(f'  {event}: {items}')
" 2>/dev/null || echo "HOOKS: parse error"
fi
```

### 1f. Count deferred tools currently loaded
```bash
echo "Count the deferred tools listed in system-reminder messages in this conversation."
echo "Each deferred tool name contributes ~10-20 tokens to context."
```

### 1g. Plugins
```bash
if [ -f ~/.claude/settings.json ]; then
  python3 -c "
import json
with open('$HOME/.claude/settings.json') as f:
    data = json.load(f)
plugins = data.get('enabledPlugins', {})
active = [k for k, v in plugins.items() if v]
print(f'PLUGINS: {len(active)} active')
for p in active:
    print(f'  {p}')
" 2>/dev/null || echo "PLUGINS: parse error"
fi
```

## Step 2: Analyze Deferred Tools

Count the deferred tools visible in the current conversation context. These are MCP
tools that have been registered. Each tool definition is roughly 50-200 tokens depending
on parameter complexity. Even "deferred" tools cost tokens for their name listing.

Scan the system-reminder messages you can see for lines matching `mcp__*` patterns.
Group by MCP server prefix and count tools per server.

## Step 3: Build the Token Budget Report

Present a table like this:

```
┌─────────────────────────────────────┬──────────┬───────────┐
│ Component                           │ Est. Tokens │ % of Base │
├─────────────────────────────────────┼──────────┼───────────┤
│ System prompt (Claude Code built-in)│ ~3,000   │ fixed     │
│ Global CLAUDE.md                    │ X,XXX    │ XX%       │
│ Project CLAUDE.md                   │ X,XXX    │ XX%       │
│ MCP: google-workspace (XX tools)    │ X,XXX    │ XX%       │
│ MCP: supabase (XX tools)            │ X,XXX    │ XX%       │
│ MCP: airtable (XX tools)            │ X,XXX    │ XX%       │
│ MCP: asana-mikey (XX tools)         │ X,XXX    │ XX%       │
│ ...                                 │          │           │
│ Plugins: vercel-plugin              │ X,XXX    │ XX%       │
│ Hooks                               │ XXX      │ X%        │
├─────────────────────────────────────┼──────────┼───────────┤
│ TOTAL BASELINE (per message)        │ XX,XXX   │ 100%      │
└─────────────────────────────────────┴──────────┴───────────┘
```

**Token estimation for MCP tools:** Each tool definition is roughly:
- Tool name: ~5 tokens
- Description: ~30-80 tokens
- Parameters schema: ~50-200 tokens
- **Average: ~100 tokens per tool**

Multiply tool count by 100 for a rough estimate.

## Step 4: Identify Cuts

For each component, recommend specific cuts:

### CLAUDE.md Optimization
Read both CLAUDE.md files and identify:
- **Sections that duplicate info derivable from code** (file structure maps, architecture docs) — CUT
- **Sections rarely relevant** to most conversations — MOVE to project memory or a separate file
- **Verbose instructions** that could be compressed — REWRITE
- **Stale information** (old project references, deprecated patterns) — DELETE
- **Per-section token count** — measure each `##` section independently

For each section, give: section name, token count, recommendation (keep/cut/compress), estimated savings.

### MCP Optimization
For each MCP server:
- How many tools does it expose?
- How often do you actually use it? (Ask the user if unsure)
- Can it be moved to a project-level config instead of global?
- Is there a lighter alternative?

**Key principle:** MCP servers used in only 1-2 projects should be in project-level
`.claude.json`, not global `settings.json`. Global = loaded everywhere. Project = loaded only there.

Recommend:
- **Move to project-level:** servers only used in specific repos
- **Disable entirely:** servers rarely used (user can enable on demand)
- **Replace with lighter alternative:** if an MCP server exposes 50 tools but you use 3

### Plugin Optimization
- Does the Vercel plugin load on every repo, even non-Vercel ones?
- Can plugins be scoped to specific projects?

## Step 5: Savings Summary

```
Potential savings: ~X,XXX tokens per message
Over 100 messages/day: ~X,XXX,XXX tokens/day saved
Estimated monthly savings: $XX-$XXX (API) or XX% fewer rate limit hits (subscription)
```

## Step 6: Offer to Apply

Use AskUserQuestion to offer applying the changes:

> Here are the changes I recommend. Which should I apply?
>
> A) Apply all recommended cuts
> B) Let me pick which ones
> C) Just show me the report, I'll do it manually

If A or B: make the changes (edit CLAUDE.md files, move MCP servers to project configs).
Always create a backup first: `cp ~/.claude/settings.json ~/.claude/settings.json.bak.$(date +%s)`

## Rules

- Never delete MCP servers without explicit user approval
- Always back up settings before modifying
- Show exact token counts, not vague "this is big"
- Be aggressive with recommendations but conservative with actions
- If you can't measure something precisely, say "estimated" and explain your method
