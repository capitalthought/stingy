---
name: stingy-ration
description: |
  Emergency token rationing mode. Activate when running low on daily token budget
  or approaching rate limits. Switches to ultra-efficient mode, exports conversation
  context for continuation on cheaper platforms, and prioritizes remaining tasks by
  token cost. Use when: "running low", "almost out of tokens", "rate limited",
  "ration", "95%", "how do I finish this somewhere else", "export conversation",
  "continue on ChatGPT", "switch to Gemini", "save my tokens".
allowed-tools:
  - Bash
  - Read
  - Write
  - Grep
  - Glob
  - AskUserQuestion
---

# /ration — Emergency Token Rationing

You are in emergency efficiency mode. The user is running low on tokens or credits.
Every token counts. Be extremely terse. No filler. No explanations unless asked.

## Step 1: Assess the Situation

```bash
echo "Check: what model are we on, what's left, what still needs to be done"
```

Ask the user (briefly):

> How much budget do you have left? (Check /cost if unsure)
> What still needs to get done this session?

## Step 2: Immediate Actions

Do these NOW, before anything else:

### Switch to cheapest model
If currently on Opus, tell the user:
```
Run: /model
Select: Claude Sonnet (5x cheaper) or Haiku (15x cheaper)
```

Haiku can handle: simple edits, running commands, file reads, formatting, test runs.
Sonnet can handle: everything except complex architecture and security review.

### Kill unnecessary context
- If conversation is long: "Run `/clear` and I'll re-read only what's needed"
- If there are MCP servers not being used: suggest disabling them temporarily

## Step 3: Triage Remaining Work

List the user's remaining tasks and categorize:

```
MUST DO (worth spending tokens on):
  1. [task] — ~XXX tokens, best model: [model]
  2. [task] — ~XXX tokens, best model: [model]

CAN EXPORT (do on a cheaper platform):
  3. [task] — export to: [platform], prompt below
  4. [task] — export to: [platform], prompt below

SKIP (not worth the tokens right now):
  5. [task] — do this tomorrow when budget resets
```

## Step 4: Export Conversation for Continuation

When tasks should move to another platform, generate a **portable context bundle**
that the user can paste into ChatGPT, Gemini, or Grok.

### Export Format

Write a file to `/tmp/stingy-export-{timestamp}.md`:

```markdown
# Context Transfer — [Project Name]

## What I'm Working On
[1-2 sentence summary of the project and current task]

## Key Files
[List only the files relevant to the remaining task, with brief descriptions]

## Current State
[What's been done, what's left, any decisions already made]

## Remaining Task
[Exact description of what needs to be done]

## Key Constraints
[Any rules, patterns, or requirements the AI needs to know]

## File Contents
[Include ONLY the specific file contents needed — not entire files.
 Use the smallest excerpt that gives enough context.]
```

Then tell the user:

```
Export saved to: /tmp/stingy-export-XXXXX.md

To continue on ChatGPT:
  1. Open chat.openai.com
  2. Paste the contents of the export file
  3. Say: "Continue from where I left off"

To continue on Gemini:
  1. Open aistudio.google.com
  2. Paste the export (Gemini handles huge context well)

To continue on Grok:
  1. Open grok.x.ai
  2. Paste the export

Copied to clipboard:
```

```bash
EXPORT_FILE=$(ls -t /tmp/stingy-export-*.md 2>/dev/null | head -1)
if [ -n "$EXPORT_FILE" ]; then
  if command -v pbcopy >/dev/null 2>&1; then
    cat "$EXPORT_FILE" | pbcopy
  elif command -v xclip >/dev/null 2>&1; then
    cat "$EXPORT_FILE" | xclip -selection clipboard
  elif command -v xsel >/dev/null 2>&1; then
    cat "$EXPORT_FILE" | xsel --clipboard --input
  else
    echo "Clipboard tool not found. Copy manually from: $EXPORT_FILE"
  fi
  echo "Export copied to clipboard — paste into any AI chat"
fi
```

## Step 5: Ultra-Efficient Mode Rules

For the rest of this session, enforce these rules:

1. **No agent spawns.** Do everything inline. Agents duplicate the full context.
2. **No full file reads.** Use Grep to find the line, then Read with offset/limit.
3. **No exploratory searches.** Only search if you know what you're looking for.
4. **Minimal output.** Don't explain what you're doing. Just do it.
5. **Batch operations.** Combine multiple edits into one tool call where possible.
6. **Skip formatting.** No tables, no headers, no decoration. Raw information only.
7. **No web searches.** Use existing knowledge. Web searches are expensive.

Tell the user:
> Rationing mode active. I'll be extremely terse and efficient.
> Estimated remaining capacity: ~[X] tool calls at current model.
> Priority tasks: [list the MUST DO items]

## Step 6: Git Stash for Tomorrow

If the user can't finish everything today, help them save state:

```bash
# Save uncommitted work
git stash -m "stingy-ration: WIP $(date +%Y-%m-%d)"
echo "Work stashed. Tomorrow: git stash pop"
```

Or commit a WIP (stage only tracked files — never use `git add -A`):
```bash
git add -u && git commit -m "WIP: [description of what's in progress]"
```

And write a brief note for tomorrow's session:

```bash
cat > /tmp/stingy-pickup-notes.md << 'EOF'
# Pickup Notes — [date]

## What was in progress
[brief description]

## What's done
[list]

## What's left
[list with priority order]

## Key context
[anything the next session needs to know]
EOF
echo "Pickup notes saved to /tmp/stingy-pickup-notes.md"
```

## Rules

- Be TERSE. Every word costs tokens.
- Prioritize ruthlessly. Not everything needs to get done today.
- The export should be copy-paste ready — no "fill in the blanks"
- Include actual file contents in exports, not just file names
- Clipboard copy is mandatory — don't make the user open the file manually
- If the user is on a subscription (not API), the "cost" is daily rate limits,
  not dollars. Frame advice around "X tool calls remaining" not "$X remaining"
