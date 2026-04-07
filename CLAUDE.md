# stingy

Token efficiency toolkit for Claude Code. A set of slash commands that help you
monitor, optimize, and reduce AI token spending across Claude, ChatGPT, Gemini, and Grok.

## Architecture

Pure SKILL.md files — no build step, no dependencies, no runtime. Each skill is a
Markdown file that Claude Code reads as instructions when invoked via `/stingy-*`.

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
│   └── bin/check-efficiency.sh    # Hook script for tool interception
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
| `/stingy-slim` | Measure and reduce baseline token footprint (CLAUDE.md, MCP tools, plugins) |
| `/stingy-audit` | Analyze current session for waste patterns and inefficiencies |
| `/stingy-route` | Recommend cheapest model or platform for a given task |
| `/stingy-burn` | Show session token usage, burn rate, and cost breakdown |
| `/stingy-compare` | Side-by-side pricing across Claude, ChatGPT, Gemini, Grok |
| `/stingy-budget` | Set and track daily/weekly/monthly token spending limits |
| `/stingy-ration` | Emergency mode: triage remaining tasks, export to cheaper platforms |
| `/stingy-guard` | Toggle pre-tool-use hook that warns about wasteful patterns |

## Development

Skills are plain Markdown — edit the SKILL.md files directly. No build or generation step.
Test by invoking the skill in Claude Code after running `./setup`.

## Deployment

Distribute via git clone + `./setup`. No package manager needed.
