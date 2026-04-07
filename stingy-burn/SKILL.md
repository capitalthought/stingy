---
name: stingy-burn
description: |
  Show current session token burn rate and cost breakdown. Estimates tokens used
  by conversation, tools, MCP calls, and agents. Compares against benchmarks.
  Use when: "burn", "burn rate", "how much have I spent", "token usage",
  "session cost", "how expensive is this session", "am I on track".
allowed-tools:
  - Bash
  - Read
  - AskUserQuestion
---

# /burn — Session Burn Rate Monitor

You are a usage dashboard. Show the user exactly where their tokens are going
in this session and how it compares to efficient usage.

## Step 1: Analyze What You Can See

Start by estimating from what's already visible in the conversation — don't ask the
user to do anything yet. Scan the session and gather:
- Approximate messages (user + assistant turns)
- Tool calls visible in the conversation
- Agent spawns (subagent dispatches)
- The model being used (check for model name references or infer from context length / response style)
- Approximate conversation length and complexity

Lead with this analysis immediately — show the user you're already working.

Then, to refine your estimates, ask:

> To sharpen these numbers, you can run `/cost` — it's a built-in Claude Code command
> that shows exact token counts and cache stats for this session. If you share the
> output, I can replace my estimates with actuals. But even without it, the breakdown
> below gives you a solid picture.

## Step 2: Estimate Token Breakdown

Based on conversation analysis, estimate:

```
SESSION BURN REPORT
═══════════════════════════════════════════════════

Model: [current model]
Session length: ~[X] messages, ~[X] tool calls

ESTIMATED TOKEN BREAKDOWN:
┌─────────────────────────┬──────────┬──────────┐
│ Category                │ Tokens   │ Cost*    │
├─────────────────────────┼──────────┼──────────┤
│ Baseline (per message)  │          │          │
│   System prompt         │ ~3,000   │          │
│   CLAUDE.md (global)    │ ~X,XXX   │          │
│   CLAUDE.md (project)   │ ~X,XXX   │          │
│   MCP tool definitions  │ ~X,XXX   │          │
│   Plugin overhead       │ ~X,XXX   │          │
│   Subtotal (×N msgs)    │ ~XX,XXX  │ $X.XX    │
├─────────────────────────┼──────────┼──────────┤
│ Conversation            │          │          │
│   User messages         │ ~X,XXX   │          │
│   Assistant responses   │ ~XX,XXX  │          │
│   Tool call results     │ ~XX,XXX  │          │
│   Subtotal              │ ~XX,XXX  │ $X.XX    │
├─────────────────────────┼──────────┼──────────┤
│ Agents spawned          │ X agents │          │
│   Agent overhead each   │ ~XX,XXX  │          │
│   Subtotal              │ ~XX,XXX  │ $X.XX    │
├─────────────────────────┼──────────┼──────────┤
│ TOTAL SESSION           │ ~XXX,XXX │ $X.XX    │
│ Baseline tax %          │     XX%  │          │
│ Productive tokens %     │     XX%  │          │
└─────────────────────────┴──────────┴──────────┘

* Cost estimated at [model] API rates. Subscription users:
  this represents your daily allocation burn, not actual dollars.
```

## Step 3: Burn Rate Projection

```
BURN RATE:
  Current: ~X,XXX tokens/minute
  Session duration: ~X minutes
  Projected session total: ~XXX,XXX tokens

DAILY PROJECTION (if you keep this pace):
  Tokens/day: ~X,XXX,XXX
  Cost/day: ~$XX (API) or ~XX% of daily allocation (subscription)

BENCHMARKS:
  Your session: XX,XXX tokens/task
  Efficient baseline: ~10,000 tokens/task (Sonnet, targeted reads)
  Wasteful baseline: ~50,000 tokens/task (Opus, full file reads, agents)
```

## Step 4: Biggest Token Sinks

Identify the top 3 token consumers in this session:

```
TOP TOKEN SINKS:
1. [specific item] — ~XX,XXX tokens
   Efficient alternative: [suggestion] (~X,XXX tokens)

2. [specific item] — ~XX,XXX tokens
   Efficient alternative: [suggestion] (~X,XXX tokens)

3. [specific item] — ~XX,XXX tokens
   Efficient alternative: [suggestion] (~X,XXX tokens)
```

## Step 5: Quick Recommendations

End with 1-3 immediate actions:

```
DO NOW:
- [action 1 — e.g., "Switch to Sonnet for the rest of this session"]
- [action 2 — e.g., "Use Read with offset/limit instead of reading whole files"]
- [action 3 — e.g., "Your CLAUDE.md is 15K tokens — run /slim to cut it"]
```

## Rules

- If you can't get exact numbers, estimate and label as estimates
- Always show the "baseline tax" percentage — this is eye-opening for users
- Compare current model cost against what it would be on a cheaper model
- Be visual — use the table format, make waste obvious
- Don't lecture. Show numbers and let them speak.
