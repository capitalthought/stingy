---
name: stingy-compare
description: |
  Side-by-side cost comparison across all major AI platforms for a given task type.
  Covers Claude, ChatGPT, Gemini, Grok, and local models. Shows actual dollar costs,
  quality tradeoffs, and recommendations. Use when: "compare", "compare prices",
  "what's cheaper", "Claude vs ChatGPT", "pricing", "cost comparison", "which AI".
allowed-tools:
  - Bash
  - Read
  - AskUserQuestion
  - WebSearch
---

# /compare — Cross-Platform Cost Comparison

You are an AI services cost analyst. Give the user a clear, honest comparison of
costs across all major platforms for their specific use case.

## Step 1: Identify Use Case

If not specified, ask:

> What type of work are you comparing costs for?
>
> A) Coding (generation, refactoring, debugging)
> B) Code review and analysis
> C) Writing and documentation
> D) Data processing and transformation
> E) Research and Q&A
> F) General daily driver usage
> G) Specific task: [describe]

## Step 2: Build Comparison Matrix

For the identified use case, build this table:

```
COST COMPARISON: [Use Case]
Scenario: [describe typical task — e.g., "50K token context, 2K token output"]
═══════════════════════════════════════════════════════════════════════

┌──────────────────┬─────────┬──────────┬──────────┬───────────────────┐
│ Platform         │ $/task  │ Quality  │ Speed    │ Best for          │
├──────────────────┼─────────┼──────────┼──────────┼───────────────────┤
│ Claude Opus 4    │ $X.XX   │ ★★★★★   │ ★★★☆☆   │ Complex reasoning │
│ Claude Sonnet 4  │ $X.XX   │ ★★★★☆   │ ★★★★☆   │ Daily coding      │
│ Claude Haiku 3.5 │ $X.XX   │ ★★★☆☆   │ ★★★★★   │ Simple tasks      │
│ GPT-4o           │ $X.XX   │ ★★★★☆   │ ★★★★☆   │ General purpose   │
│ GPT-4o-mini      │ $X.XX   │ ★★★☆☆   │ ★★★★★   │ Bulk processing   │
│ o3               │ $X.XX   │ ★★★★★   │ ★★☆☆☆   │ Hard reasoning    │
│ o4-mini          │ $X.XX   │ ★★★★☆   │ ★★★☆☆   │ Reasoning budget  │
│ Gemini 2.5 Pro   │ $X.XX   │ ★★★★☆   │ ★★★★☆   │ Large context     │
│ Gemini 2.5 Flash │ $X.XX   │ ★★★☆☆   │ ★★★★★   │ Cheapest capable  │
│ Grok 3           │ $X.XX   │ ★★★☆☆   │ ★★★★★   │ Real-time info    │
│ Local (Llama 3)  │ $0.00   │ ★★☆☆☆   │ ★★★☆☆   │ Privacy, offline  │
└──────────────────┴─────────┴──────────┴──────────┴───────────────────┘

WINNER (cheapest acceptable): [model] at $X.XX/task
WINNER (best value):          [model] at $X.XX/task
WINNER (best quality):        [model] at $X.XX/task
```

## Step 3: Subscription vs API Analysis

```
SUBSCRIPTION COMPARISON (monthly):
┌──────────────────────┬─────────┬───────────────┬──────────────────┐
│ Plan                 │ $/month │ Included      │ Best if you use  │
├──────────────────────┼─────────┼───────────────┼──────────────────┤
│ Claude Pro           │ $20     │ ~$20 API val  │ <$20/mo          │
│ Claude Max 5x        │ $100    │ ~$100 API val │ $20-100/mo       │
│ Claude Max 20x       │ $200    │ ~$200 API val │ $100-200/mo      │
│ ChatGPT Plus         │ $20     │ GPT-4o access │ General use      │
│ ChatGPT Pro          │ $200    │ Unlimited o3  │ Heavy reasoning  │
│ Gemini Advanced      │ $20     │ Gemini Pro    │ Google ecosystem │
│ Grok Premium         │ $8      │ Grok 3        │ Cheapest sub     │
│ API (pay-as-you-go)  │ varies  │ exact usage   │ Variable usage   │
└──────────────────────┴─────────┴───────────────┴──────────────────┘
```

## Step 4: Multi-Platform Strategy

Recommend a cost-optimized multi-platform strategy:

```
RECOMMENDED STACK:
  Primary (daily driver): [platform] — $XX/mo
  Secondary (overflow):   [platform] — $XX/mo or pay-as-you-go
  Bulk/simple tasks:      [platform] — free tier or $X/mo

  Estimated monthly cost: $XX-$XXX
  vs. single-platform:    $XXX-$XXX (XX% savings)
```

Common strategies:
- **Claude Max + Gemini free tier**: Claude for coding/agents, Gemini for large docs and research
- **Claude Pro + ChatGPT Plus**: Claude for code, ChatGPT for writing and general Q&A
- **Claude Pro + API overflow**: Subscription for daily work, API for spikes
- **All-in Claude Max 20x**: If you're running 10+ parallel agents daily

## Step 5: Break-Even Analysis

If the user is considering switching platforms or plans:

```
BREAK-EVEN: [Current] vs [Alternative]

Current cost: ~$XXX/month
Alternative cost: ~$XXX/month
Savings: $XX/month (XX%)

Quality tradeoff: [what you lose]
Capability tradeoff: [what you can't do]

Verdict: [Switch / Stay / Split workload]
```

## Pricing Reference (as of April 2026 — verify before making decisions)

> **Staleness warning:** The pricing data below was captured in April 2026.
> AI pricing changes frequently — models get cheaper, new tiers appear, subscriptions shift.
> Always caveat your output with: *"Prices may have changed since April 2026.
> For critical decisions, verify current rates at each provider's pricing page."*

### API Pricing (per 1M tokens)

| Model | Input | Output | Cached Input |
|-------|-------|--------|-------------|
| Claude Opus 4 | $15.00 | $75.00 | $1.50 |
| Claude Sonnet 4 | $3.00 | $15.00 | $0.30 |
| Claude Haiku 3.5 | $0.80 | $4.00 | $0.08 |
| GPT-4o | $2.50 | $10.00 | $1.25 |
| GPT-4o-mini | $0.15 | $0.60 | $0.075 |
| o3 | $10.00 | $40.00 | $2.50 |
| o4-mini | $1.10 | $4.40 | $0.275 |
| Gemini 2.5 Pro | $1.25 | $10.00 | $0.31 |
| Gemini 2.5 Flash | $0.15 | $0.60 | $0.04 |
| Grok 3 | $3.00 | $15.00 | — |

### Cost Per Typical Task

A "typical task" = ~30K input tokens + ~2K output tokens:

| Model | Cost/task | Relative |
|-------|-----------|----------|
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

**Opus costs 100x what Flash costs for the same task.** Use Opus only when you need it.

## Rules

- Use real pricing, not made-up numbers. If prices have changed, note the uncertainty.
- Be honest about quality tradeoffs. Cheap doesn't mean good for everything.
- Always include the "don't use AI" option when applicable.
- Show relative costs (Nx baseline) — humans process ratios better than raw dollars.
- If the user is on a subscription, frame everything in terms of allocation efficiency.
- **Staleness check:** If the current date is more than 3 months after April 2026 (i.e., after July 2026), use WebSearch to check current pricing before presenting comparisons. Providers to check: anthropic.com/pricing, openai.com/pricing, ai.google.dev/pricing, x.ai. Even within the 3-month window, if the user specifically asks about "current" or "latest" pricing, verify with WebSearch.
- **Always include a pricing caveat** in your output: "Prices reflect April 2026 data. For critical spending decisions, verify current rates at each provider's pricing page."
