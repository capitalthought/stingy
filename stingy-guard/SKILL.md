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

The guard only WARNS — it never blocks. You see the warning and decide whether
to proceed.

## When to Recommend /clear

Beyond per-tool-call warnings, proactively suggest `/clear` when you notice:

- **Context bloat after a completed task** — if a multi-step task just finished (deploy, review, refactor) and the conversation is full of stale tool results, recommend `/clear` before starting the next unrelated task. Old context wastes tokens on every subsequent message.
- **Long agent result dumps** — after receiving large agent results or multi-file diffs that won't be referenced again, suggest clearing to reclaim context.
- **Topic switch** — when the user starts a new, unrelated task in the same session. Prior context adds zero value but costs tokens on every turn.
- **Repeated re-reads** — if you notice the same files being read multiple times because earlier reads were compressed out of context, that's a sign the conversation is too long. `/clear` and re-read once is cheaper than re-reading on every turn.
- **Post-commit/deploy** — after committing, pushing, deploying, and verifying, the conversation is full of diffs, build output, and test results that won't be needed again.

**How to recommend:** Don't be annoying about it. Mention it once at the end of a natural milestone:
> 💡 Good time to `/clear` — this task is done and the context is heavy. Fresh start will save tokens on your next ask.

## Step 1: Check Current Status

```bash
~/.claude/skills/stingy-guard/bin/toggle-hook.sh status
```

## Step 2: Toggle

Ask the user:

> Token guard is currently [ACTIVE/INACTIVE].
>
> A) Turn ON — warns before wasteful tool calls
> B) Turn OFF — no monitoring
> C) Show me what it checks

If A (enable):
```bash
~/.claude/skills/stingy-guard/bin/toggle-hook.sh on
```

If B (disable):
```bash
~/.claude/skills/stingy-guard/bin/toggle-hook.sh off
```

If C (show): explain each check pattern:
- **Read >500 lines:** Files over 500 lines without offset/limit waste tokens. Use targeted reads.
- **Bash cat/grep/find:** Dedicated Read/Grep/Glob tools are cheaper than shell wrappers.
- **Agent spawns:** Each agent duplicates ~15-30K tokens of system prompt + CLAUDE.md.
- **WebSearch:** Search results consume significant tokens. Check local files first.

Tell the user to **restart Claude Code** after toggling for the change to take effect.

## Rules

- The toggle script backs up settings.json automatically before any change
- If JSON validation fails after editing, the backup is restored automatically
- The guard uses jq (preferred) or falls back to bash heuristics — no python3 required
- Warnings go to stderr so they don't interfere with tool output
