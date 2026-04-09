# stingy

**Save money on AI.** Stingy shows you where you're overspending on Claude Code, ChatGPT, Gemini, and Grok — and helps you cut costs without losing quality.

## The problem

AI tools are expensive. Claude Opus costs 100x what Gemini Flash costs for the same task. Your system prompt and MCP tools add a hidden "token tax" to every single message. Most people don't know what they're spending or where the waste is.

## What stingy does

8 slash commands you can type in Claude Code:

| Command | What it does |
|---------|-------------|
| `/stingy-slim` | **Start here.** Finds what's making your AI sessions expensive and shows you how to fix it |
| `/stingy-audit` | Reviews your current session for wasted tokens |
| `/stingy-route` | Tells you the cheapest AI that can handle any task |
| `/stingy-burn` | Shows your session cost breakdown and burn rate |
| `/stingy-compare` | Side-by-side pricing across Claude, ChatGPT, Gemini, Grok |
| `/stingy-budget` | Set a daily/weekly spending limit and track it |
| `/stingy-ration` | Running low on tokens? Export your work to a cheaper AI without losing context |
| `/stingy-guard` | Auto-warns before you do something wasteful (like reading a 5000-line file) |

## See it in action

<!-- TODO: Add terminal recording (asciinema or vhs) -->
> Try it yourself: install stingy and type `/stingy-slim` in Claude Code to see your token footprint.

## Install (30 seconds)

Requires [Claude Code](https://docs.anthropic.com/en/docs/claude-code) and Git.

```bash
git clone https://github.com/capitalthought/stingy.git ~/stingy
cd ~/stingy && ./setup
```

Then open Claude Code and type `/stingy-slim` to see your token footprint.

## Uninstall

```bash
cd ~/stingy && ./setup --uninstall
```

## How it works

Pure Markdown. Each command is a SKILL.md file — instructions that Claude reads when you invoke the slash command. No build step, no runtime, no dependencies beyond Claude Code itself.

## License

MIT
