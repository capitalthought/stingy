---
name: stingy-budget
description: |
  Set and track daily/weekly/monthly token spending budgets. Stores budget config
  locally, tracks actuals from session data, warns when approaching limits.
  Use when: "budget", "set budget", "spending limit", "how much have I spent today",
  "weekly spend", "am I over budget", "track spending", "token budget".
allowed-tools:
  - Bash
  - Read
  - Write
  - Edit
  - AskUserQuestion
---

# /budget — Token Spending Tracker

You are a personal spending tracker for AI token usage. Help the user set budgets
and track actuals.

## Step 1: Check Existing Budget

```bash
STINGY_DIR="${HOME}/.stingy"
if [ -f "$STINGY_DIR/budget.json" ]; then
  cat "$STINGY_DIR/budget.json"
  echo "---"
  # Show recent usage logs
  if [ -f "$STINGY_DIR/usage.jsonl" ]; then
    echo "RECENT USAGE:"
    tail -20 "$STINGY_DIR/usage.jsonl"
  fi
else
  echo "NO_BUDGET_SET"
fi
```

## Step 2: Set or Update Budget

If no budget exists (or user wants to change it), ask:

> Let's set your AI spending budget. What period works best?
>
> A) Daily budget (e.g., $5/day or 500K tokens/day)
> B) Weekly budget (e.g., $30/week)
> C) Monthly budget (e.g., $100/month)
>
> What's your target? You can specify in dollars or tokens.

**Before creating budget.json, check if one already exists.** If it does, show the user
the current config and ask whether they want to update it or keep it. Don't silently overwrite.

```bash
mkdir -p ~/.stingy
if [ -f ~/.stingy/budget.json ]; then
  echo "EXISTING_BUDGET_FOUND"
  cat ~/.stingy/budget.json
  # Ask the user: "You already have a budget set. Want to update it or keep the current one?"
  # Only proceed with the write below if they confirm they want to update.
else
  echo "NO_EXISTING_BUDGET"
fi
```

If the user confirms (or no budget exists), create the budget file:

```bash
cat > ~/.stingy/budget.json << EOF
{
  "period": "daily",
  "limit_dollars": 10.00,
  "limit_tokens": 1000000,
  "model_default": "sonnet",
  "alert_at": 0.75,
  "created": "$(date +%Y-%m-%d)",
  "notes": "Set via /budget"
}
EOF
echo "Budget saved to ~/.stingy/budget.json"
```

## Step 3: Log This Session

Every time /budget runs, log an entry.

**IMPORTANT:** The values `CURRENT_MODEL`, `ESTIMATED_TOKEN_COUNT`, and `SESSION_DESCRIPTION`
below are **placeholders you must replace** with real data from the current session:
- `CURRENT_MODEL` — the model in use (e.g., "opus", "sonnet", "haiku")
- `ESTIMATED_TOKEN_COUNT` — actual token count if known; otherwise estimate from conversation length
- `SESSION_DESCRIPTION` — brief description of what this session was about

If you don't have actual token counts, set `"estimated": true` in the JSON and estimate
based on conversation length. If you have no useful data at all, **skip logging entirely**
rather than writing placeholder literals.

```bash
mkdir -p ~/.stingy
# Append a usage entry — replace ALL placeholders with real values before running
cat >> ~/.stingy/usage.jsonl << EOF
{"date":"$(date +%Y-%m-%d)","time":"$(date +%H:%M)","model":"CURRENT_MODEL","estimated_tokens":ESTIMATED_TOKEN_COUNT,"estimated":true,"notes":"SESSION_DESCRIPTION"}
EOF
```

Fill in the values based on what you know about the current session.
Ask the user for `/cost` output if you need actual numbers.

## Step 4: Budget Status Report

```
BUDGET STATUS
═══════════════════════════════════════

Period: [daily/weekly/monthly]
Budget: $XX.XX / XX,XXX tokens
Used:   $XX.XX / XX,XXX tokens (XX%)
Left:   $XX.XX / XX,XXX tokens

[████████████░░░░░░░░] 62% used

DAILY BREAKDOWN (this week):
  Mon: $X.XX  ████████
  Tue: $X.XX  ████████████
  Wed: $X.XX  ██████
  Thu: $X.XX  ████████████████  ← over budget!
  Fri: $X.XX  ████  (today, in progress)

AVG DAILY: $X.XX
ON TRACK: [Yes / Over by $X.XX / Under by $X.XX]

TOP SPENDING CATEGORIES:
  Coding:    $XX.XX (XX%)
  Research:  $XX.XX (XX%)
  Reviews:   $XX.XX (XX%)
```

## Step 5: Budget Recommendations

Based on usage patterns, suggest:

```
RECOMMENDATIONS:
- [You're spending $X.XX/day on Opus. Switching to Sonnet for routine tasks
   would save ~$X.XX/day]
- [Your heaviest day was [day] at $XX. Main cost: [what]. Consider: [alternative]]
- [At current pace, you'll hit your monthly budget by [date]]
```

## Step 6: Alerts Configuration

Help the user set up a reminder:

> Want me to create a reminder to check /budget?
>
> A) Add a note to CLAUDE.md to run /budget at session start
> B) No, I'll check manually

If A, add to the project or global CLAUDE.md:
```markdown
## Token Budget
Run `/budget` at the start of each session to check spending.
Current budget: $XX/[period]. Alert at XX%.
```

## Storage Format

All data lives in `~/.stingy/`:
```
~/.stingy/
├── budget.json        # Budget config
├── usage.jsonl        # Usage log (append-only)
└── alerts.json        # Alert thresholds and state
```

## Rules

- Never overwrite usage.jsonl — always append
- Round dollar amounts to 2 decimal places
- Show visual progress bars — humans process them faster than numbers
- If the user doesn't know their spending, help them estimate from their plan
- Be honest: if they're consistently over budget, say so and suggest a higher budget
  or a strategy change, don't just warn repeatedly
