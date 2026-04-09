# Contributing to stingy

## How it works

Each skill is a `SKILL.md` file — plain Markdown that Claude Code reads as instructions when you invoke the slash command. No build step, no runtime. The `setup` script symlinks each skill directory into `~/.claude/skills/`.

Shell scripts live in `stingy-<name>/bin/` alongside the SKILL.md.

## Adding a new skill

1. Create `stingy-foo/SKILL.md` with the skill instructions.
2. Add `stingy-foo` to the `SKILLS` array in `setup`.
3. Update the skills table in `README.md` and `CLAUDE.md`.
4. Run `./setup --yes` and invoke `/stingy-foo` in Claude Code to verify.

If the skill needs shell scripts, put them in `stingy-foo/bin/`. The setup script automatically symlinks `bin/` when it exists.

## Testing

```bash
./setup --yes          # Install/reinstall skills
```

Then open Claude Code and invoke the skill. That's the whole test loop.

For skills with shell scripts:

```bash
shellcheck stingy-foo/bin/*.sh
```

For changes to the guard hook specifically:

```bash
tests/test-guard-hook.sh
```

## Style guidelines

- **Keep SKILL.md files concise.** Every token in a SKILL.md gets loaded on every invocation — this is a token efficiency tool, so bloated skills are ironic and costly.
- **Self-contained.** Skills should work with no external dependencies beyond `bash` and optionally `jq`. Document any dependency and provide a fallback.
- **No build step.** If your skill requires compilation, transpilation, or code generation, reconsider the approach.
- **Data goes in `~/.stingy/`.** Don't write to arbitrary locations.

## PR process

PRs auto-merge after CI passes. Keep changes focused — one skill per PR is ideal. If you're touching multiple skills, split into separate PRs unless they're tightly coupled.

Before opening a PR:
- Run `shellcheck` on any shell scripts you touched
- Invoke the skill in Claude Code and confirm it works end-to-end
- Update `README.md` and `CLAUDE.md` if you added or renamed a skill
