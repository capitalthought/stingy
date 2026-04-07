---
name: stingy-audit
description: |
  Analyze the current Claude Code session for token waste. Reviews tool usage patterns,
  agent spawns, file reads, MCP calls, and conversation length to find where tokens
  were burned unnecessarily. Gives specific recommendations for the rest of the session.
  Use when: "audit", "am I wasting tokens", "session audit", "how efficient am I",
  "token check", "why is this session so expensive", "efficiency check".
allowed-tools:
  - Bash
  - Read
  - Grep
  - Glob
  - AskUserQuestion
---

# /stingy-audit — Session Efficiency Audit

You are a token efficiency analyst. Review this conversation session and identify
where tokens were wasted and how the user can be more efficient going forward.

## Step 1: Session Metrics

First, gather what you can about the current session:

```bash
echo "SESSION_START: Check conversation context for approximate session length"
echo "Check /cost output if available"
```

Tell the user to run `/cost` if they haven't recently, so you can see the output.

## Step 2: Analyze This Conversation

Review the conversation history visible to you and categorize every tool call and
response into these buckets:

### Waste Category: Oversized Reads
- **Pattern:** `Read` of entire large files when only a section was needed
- **Fix:** Use `offset` and `limit` parameters, or `Grep` to find the relevant section first
- **Token cost:** Each unnecessary line is ~10 tokens
- Flag every Read that returned >200 lines where the user only needed <50

### Waste Category: Bash Instead of Dedicated Tools
- **Pattern:** `Bash(cat file)`, `Bash(grep pattern)`, `Bash(find . -name ...)` 
- **Fix:** Use `Read`, `Grep`, `Glob` tools — they're cheaper (better formatted, less overhead)
- Each Bash wrapper adds ~50-100 tokens of shell overhead vs the dedicated tool

### Waste Category: Redundant Agent Spawns
- **Pattern:** Launching an Agent for something that could be done with a single tool call
- **Fix:** Use direct Grep/Read/Glob for simple lookups. Reserve Agent for multi-step research.
- Each Agent spawn duplicates the full system prompt + CLAUDE.md (~15K-30K tokens)

### Waste Category: MCP Tool Calls for Simple Tasks
- **Pattern:** Using an MCP tool when a simpler approach exists
- **Example:** Using google-workspace MCP to read a file that's already local
- **Fix:** Use local tools first, MCP only for external services

### Waste Category: Verbose Prompts
- **Pattern:** Long user messages that repeat context Claude already has
- **Fix:** Reference previous messages instead of restating. Be terse.

### Waste Category: Long Conversations Without Clearing
- **Pattern:** Session has gone through multiple unrelated topics
- **Fix:** Use `/clear` when switching topics. Each message in a long conversation
  re-sends ALL previous context.

### Waste Category: Trial-and-Error Loops
- **Pattern:** Multiple failed attempts at the same thing (wrong file path, wrong syntax)
- **Fix:** Read the file/docs first, then act. One well-informed attempt beats three guesses.

### Waste Category: Unnecessary Tool Searches
- **Pattern:** Using `ToolSearch` to find tools that should be known
- **Fix:** Memorize common tools or check the deferred tools list once per session

## Step 3: Build the Audit Report

Present findings in this format:

```
SESSION AUDIT
═══════════════════════════════════════════════════

Estimated session tokens: ~XXX,XXX
Estimated waste: ~XX,XXX tokens (XX%)

TOP WASTE AREAS:
1. [Category] — ~X,XXX tokens wasted
   Example: [specific tool call from this session]
   Fix: [specific recommendation]

2. [Category] — ~X,XXX tokens wasted
   Example: [specific tool call from this session]
   Fix: [specific recommendation]

...

EFFICIENCY SCORE: X/10

QUICK WINS FOR REST OF SESSION:
- [specific actionable tip]
- [specific actionable tip]
- [specific actionable tip]
```

## Step 4: Model Usage Analysis

Check what model is being used in this session and whether it's appropriate:

- **Opus** (~$15/$75 per 1M input/output): Only for complex architecture, nuanced
  code review, multi-file refactors, or creative writing. If this session is doing
  simple file edits, lookups, or running commands — it should be Sonnet or Haiku.

- **Sonnet** (~$3/$15 per 1M): Good default for most coding tasks. Code generation,
  bug fixes, test writing, standard refactors.

- **Haiku** (~$0.80/$4 per 1M): Perfect for simple lookups, file reads, running
  tests, formatting, simple edits. 15-20x cheaper than Opus.

Recommend model switches for the remainder of the session based on what tasks remain.

In Claude Code, the user can switch with `/model` command.

## Step 5: MCP Usage in This Session

Review which MCP tools were called in this session:
- Were any MCP calls unnecessary? (Could have been done with local tools)
- Were any MCP servers loaded but never used? (Wasted baseline tokens)
- Were MCP responses oversized? (Some servers return massive JSON blobs)

## Rules

- Be specific — reference actual tool calls from THIS session, not hypotheticals
- Give token estimates for each waste area
- Be direct about the efficiency score — most sessions are 4-6/10
- Don't sugarcoat. If the session was wasteful, say so.
- End with the 3 most impactful changes for the rest of the session
