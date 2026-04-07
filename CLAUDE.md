# stingy

Token efficiency toolkit for Claude Code. A set of slash commands that help you
monitor, optimize, and reduce AI token spending across Claude, ChatGPT, Gemini, and Grok.

## Architecture

Pure SKILL.md files — no build step, no runtime. Each skill is a Markdown file that
Claude Code reads as instructions when invoked via `/stingy-*`.

Optional dependency: `jq` (for stingy-guard hook toggling). Falls back to bash if missing.

Skills are installed by symlinking into `~/.claude/skills/`. The `setup` script
handles this. Data (budgets, usage logs) is stored in `~/.stingy/`.

## Source Structure

```
stingy/
├── CLAUDE.md
├── setup                          # Install script — symlinks skills
├── stingy-slim/SKILL.md           # Optimize CLAUDE.md + MCP token footprint
├── stingy-audit/SKILL.md          # Session efficiency audit
├── stingy-route/SKILL.md          # Smart task router (cheapest model/platform)
├── stingy-burn/SKILL.md           # Session burn rate monitor
├── stingy-compare/SKILL.md        # Cross-platform cost comparison
├── stingy-budget/SKILL.md         # Token spending tracker
├── stingy-ration/SKILL.md         # Emergency low-token mode + export
├── stingy-guard/SKILL.md          # Pre-tool-use efficiency hook
│   └── bin/
│       ├── check-efficiency.sh    # Hook script for tool interception
│       └── toggle-hook.sh         # Safely add/remove hook from settings.json
├── README.md                      # Plain-English project description
├── .claude/
│   └── statusline-stingy.sh
└── .github/
    └── workflows/
        └── auto-merge.yml
```

## Commands

```bash
./setup     # Install all skills into ~/.claude/skills/
```

### Available Skills

| Skill | What it does |
|-------|-------------|
| `/stingy-slim` | Find what's making your AI sessions expensive and fix it |
| `/stingy-audit` | Check if you're wasting tokens in this session |
| `/stingy-route` | Get the cheapest AI for any task |
| `/stingy-burn` | See your session cost breakdown and burn rate |
| `/stingy-compare` | Compare prices across Claude, ChatGPT, Gemini, Grok |
| `/stingy-budget` | Set a spending limit and track it |
| `/stingy-ration` | Running low? Export your work to a cheaper AI without losing context |
| `/stingy-guard` | Auto-warn before wasteful tool calls |

## Development

Skills are plain Markdown — edit the SKILL.md files directly. No build or generation step.
Test by invoking the skill in Claude Code after running `./setup`.

## Deployment

Distribute via git clone + `./setup`. No package manager needed.
