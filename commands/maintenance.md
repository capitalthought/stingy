---
name: stingy:maintenance
description: Check for upstream changes to AI model pricing, names, context windows, and rate limits that could make stingy's knowledge stale
allowed-tools:
  - Bash
  - Read
  - Grep
  - Glob
  - Edit
  - Write
  - WebSearch
  - WebFetch
  - AskUserQuestion
---

Check for upstream changes to AI model pricing, naming, context windows, and platform offerings that could cause stingy's hardcoded knowledge to go stale.

## When to run

- Monthly, as part of plugin maintenance (session-start hook nudges after 30 days)
- When a provider announces pricing changes or new models
- When a user reports incorrect pricing or model info
- After major model releases (new Claude, GPT, Gemini, Grok versions)

## Checks

Run all checks in parallel where possible. Collect findings into a single report at the end.

### 1. API Pricing Accuracy

The following files embed hardcoded per-token pricing. Verify each against the provider's current pricing page.

**Files with pricing data:**

| File | What it contains |
|------|-----------------|
| `stingy-compare/SKILL.md` | Full pricing table (lines ~126-157), cost-per-task table, subscription comparison |
| `stingy-route/SKILL.md` | Pricing reference table (lines ~128-141), cost-per-task estimates in routing rules |
| `stingy-audit/SKILL.md` | Model pricing in recommendations (lines ~110-118) |
| `stingy-budget/SKILL.md` | Default model assumption ("sonnet"), cost estimation references |
| `stingy-burn/SKILL.md` | Benchmark cost assumptions (Opus vs Sonnet vs Haiku) |

**Current hardcoded values to verify:**

| Model | Input (per 1M) | Output (per 1M) | Cached Input | Source |
|-------|----------------|-----------------|-------------|--------|
| Claude Opus 4 | $15.00 | $75.00 | $1.50 | stingy-compare |
| Claude Sonnet 4 | $3.00 | $15.00 | $0.30 | stingy-compare |
| Claude Haiku 3.5 | $0.80 | $4.00 | $0.08 | stingy-compare |
| GPT-4o | $2.50 | $10.00 | $1.25 | stingy-compare |
| GPT-4o-mini | $0.15 | $0.60 | $0.075 | stingy-compare |
| o3 | $10.00 | $40.00 | $2.50 | stingy-compare |
| o4-mini | $1.10 | $4.40 | $0.275 | stingy-compare |
| Gemini 2.5 Pro | $1.25 | $10.00 | $0.31 | stingy-compare |
| Gemini 2.5 Flash | $0.15 | $0.60 | $0.04 | stingy-compare |
| Grok 3 | $3.00 | $15.00 | — | stingy-compare |

Use WebSearch to check current pricing at:
- `anthropic.com/pricing`
- `openai.com/api/pricing`
- `ai.google.dev/pricing`
- `x.ai` (Grok pricing)

Flag any price that has changed. Note the direction (cheaper/more expensive) and magnitude.

### 2. Model Names and IDs

Check if any models have been renamed, versioned, or deprecated:

**Currently referenced model names:**
- Claude: Opus 4, Sonnet 4, Haiku 3.5
- OpenAI: GPT-4o, GPT-4o-mini, o3, o4-mini
- Google: Gemini 2.5 Pro, Gemini 2.5 Flash
- xAI: Grok 3

Check for:
- New model versions (e.g., Claude 5, GPT-5, Gemini 3)
- Renamed models (e.g., if "GPT-4o" becomes "GPT-4o-2025-XX")
- Deprecated models that stingy still references
- New models that should be added to routing/comparison tables

### 3. Subscription Plan Changes

`stingy-compare/SKILL.md` (lines ~70-78) contains subscription pricing:

| Plan | Current Price | Check |
|------|-------------|-------|
| Claude Pro | $20/mo | anthropic.com/pricing |
| Claude Max 5x | $100/mo | anthropic.com/pricing |
| Claude Max 20x | $200/mo | anthropic.com/pricing |
| ChatGPT Plus | $20/mo | openai.com/chatgpt/pricing |
| ChatGPT Pro | $200/mo | openai.com/chatgpt/pricing |
| Gemini Advanced | $20/mo | one.google.com |
| Grok Premium | $8/mo | x.ai |

Flag any plan that changed price, was renamed, discontinued, or if new tiers were added.

### 4. Context Window Sizes

`stingy-route/SKILL.md` references Gemini's "1M context" as a routing factor. Verify:

| Model | Assumed Context | Check |
|-------|----------------|-------|
| Claude Opus/Sonnet | 200K | anthropic.com/claude |
| GPT-4o | 128K | openai.com/api |
| Gemini 2.5 Pro | 1M | ai.google.dev |
| Gemini 2.5 Flash | 1M | ai.google.dev |

Flag if any context windows changed (especially if competitors now match Gemini's 1M).

### 5. Rate Limits and Token Limits

`stingy-burn/SKILL.md` and `stingy-ration/SKILL.md` reference:
- Daily allocation concepts for subscription users
- The `/cost` built-in command for checking usage
- Model switching via `/model` command

Verify these Claude Code features still exist and work as described. Check if rate limit structures have changed (e.g., new tier-based throttling).

### 6. Cost-Per-Task Calculations

`stingy-compare/SKILL.md` (lines ~143-157) has a "typical task" cost table assuming 30K input + 2K output tokens. Recalculate with any updated prices and verify the relative cost ratios still hold:

| Model | Current $/task | Current Relative |
|-------|---------------|-----------------|
| Gemini Flash | $0.006 | 1x (baseline) |
| GPT-4o-mini | $0.006 | 1x |
| Haiku 3.5 | $0.032 | 5x |
| Sonnet 4 | $0.120 | 20x |
| GPT-4o | $0.095 | 16x |
| Gemini Pro | $0.058 | 10x |
| Grok 3 | $0.120 | 20x |
| o4-mini | $0.042 | 7x |
| Opus 4 | $0.600 | 100x |
| o3 | $0.380 | 63x |

The "Opus costs 100x what Flash costs" headline claim should be reverified.

### 7. Routing Rule Accuracy

`stingy-route/SKILL.md` has task→model routing tables. Check if the recommendations still make sense given current model capabilities:

- Are there new models that should be recommended for certain tasks?
- Has any model significantly improved/degraded at specific tasks?
- Are the cost estimates per task still in the right ballpark?

### 8. Staleness Warning Dates

Multiple SKILL.md files reference "April 2026" as the data capture date:
- `stingy-compare/SKILL.md` line ~121: "captured in April 2026"
- `stingy-compare/SKILL.md` line ~167: "3 months after April 2026"
- `stingy-route/SKILL.md` line ~121: staleness warning

After maintenance, update these dates to reflect the current verification date.

### 9. Platform Export Instructions

`stingy-ration/SKILL.md` (lines ~128-130) references platform URLs for exporting work:
- `chat.openai.com` — still the correct ChatGPT URL?
- `aistudio.google.com` — still the correct Gemini URL?
- `grok.x.ai` — still the correct Grok URL?

Check that these URLs resolve and are still the right entry points.

## Report Format

After all checks complete, produce a summary:

```
## stingy:maintenance Report — {date}

| Check | Status | Details |
|-------|--------|---------|
| API pricing | ✅/⚠️ | any price changes |
| Model names | ✅/⚠️ | new/renamed/deprecated models |
| Subscription plans | ✅/⚠️ | plan changes |
| Context windows | ✅/⚠️ | size changes |
| Rate limits | ✅/⚠️ | structure changes |
| Cost-per-task math | ✅/⚠️ | recalculated ratios |
| Routing rules | ✅/⚠️ | outdated recommendations |
| Staleness dates | ✅/⚠️ | dates needing update |
| Platform URLs | ✅/⚠️ | broken or changed URLs |

### Action Items
1. [Critical] ...
2. [High] ...
3. [Medium] ...
```

For each finding, include:
- What changed
- Which file(s) need updating (with line numbers)
- Suggested fix (exact text replacement if possible)

## After Running

**Always stamp the run**, even if no issues were found:

```bash
STINGY_DIR="$(git rev-parse --show-toplevel 2>/dev/null || pwd)"
mkdir -p "$STINGY_DIR/generated"
echo '{"lastRun":"'"$(date -u +%Y-%m-%dT%H:%M:%SZ)"'"}' > "$STINGY_DIR/generated/maintenance.json"
```

This file is checked into the repo so the timestamp is shared across machines and clones. The session-start hook checks it — if it's been more than 30 days (or never run), stingy nudges the user to run `/stingy:maintenance`.

**Commit the updated timestamp:**

```bash
git add generated/maintenance.json
git commit -m "chore: stamp stingy:maintenance run $(date +%Y-%m-%d)"
```

If action items are found:
1. Fix Critical/High items immediately (update pricing tables, model names)
2. Create GitHub issues for Medium/Low items
3. Update staleness dates in all affected SKILL.md files
4. Run tests: `tests/test-guard-hook.sh`
5. Commit all changes
