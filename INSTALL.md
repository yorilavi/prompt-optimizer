# Installing `prompt-optimizer`

A skill for Claude Code that runs an iterative Claude ↔ GPT review loop on any prompt and ships you an optimized version.

---

## Requirements

- **Claude Code** — CLI, VS Code extension, or JetBrains plugin. Any of them work.
- **Optional: [Codex CLI](https://github.com/openai/codex)** — enables automated GPT review. Without it, the skill falls back to a "paste this into ChatGPT" mode automatically. You do not need to install Codex to use the skill.

---

## Quick install (recommended)

Unzip the archive, then from inside the unzipped folder:

**macOS / Linux / WSL / Git Bash on Windows:**

```sh
sh install.sh
```

**Windows PowerShell:**

```powershell
powershell -ExecutionPolicy Bypass -File .\install.ps1
```

Both scripts:

1. Copy `SKILL.md` and `CHANGELOG.md` to the Claude Code skills directory.
2. Back up any previous install to `<target>.bak.<timestamp>` instead of overwriting.
3. Print the installed version and next steps.

Skip to [Verify the install](#verify-the-install) once you've run one.

---

## Manual install

If you'd rather see exactly what's happening, do it by hand. The skill lives in a single directory under `~/.claude/skills/`.

### macOS / Linux

```sh
mkdir -p ~/.claude/skills
cp -r prompt-optimizer ~/.claude/skills/
```

The final layout must be:

```
~/.claude/skills/prompt-optimizer/SKILL.md
~/.claude/skills/prompt-optimizer/CHANGELOG.md
```

If you end up with `~/.claude/skills/prompt-optimizer/prompt-optimizer/SKILL.md` (one folder too deep), move the inner folder up one level.

### Windows

```powershell
$dest = "$env:USERPROFILE\.claude\skills"
New-Item -ItemType Directory -Path $dest -Force | Out-Null
Copy-Item -Recurse -Path .\prompt-optimizer -Destination $dest
```

Final layout:

```
%USERPROFILE%\.claude\skills\prompt-optimizer\SKILL.md
%USERPROFILE%\.claude\skills\prompt-optimizer\CHANGELOG.md
```

---

## Verify the install

1. **Restart Claude Code** (or start a new session). Skills are read at session start.
2. In any session, run:

   ```
   /skills
   ```

   You should see `prompt-optimizer` in the list.

3. Try it:

   ```
   /prompt-optimizer
   ```

   Or describe what you want in natural language: *"Use the prompt optimizer skill to improve this prompt: …"*

---

## Troubleshooting

**Claude doesn't see the skill.**
Almost always a nested-folder problem. The `SKILL.md` file must be exactly one level under `~/.claude/skills/prompt-optimizer/`. If you see `~/.claude/skills/prompt-optimizer/prompt-optimizer/SKILL.md`, move the inner folder up.

**"Codex not found" or similar.**
Expected if you don't have Codex installed. The skill falls back to manual mode automatically — it'll give you a block to paste into ChatGPT instead. No action needed.

**Lint warnings appear in VS Code when viewing `SKILL.md`.**
Safe to ignore. The `metadata:` block holds version and author info; VS Code's skill linter only flags top-level fields it doesn't recognize.

**I ran the install script but nothing changed.**
The script no-ops if you ran it from inside `~/.claude/skills/prompt-optimizer/` itself (the author's dev case). Run it from your `Downloads/` folder or wherever you unzipped the archive.

---

## Uninstall

```sh
rm -rf ~/.claude/skills/prompt-optimizer
```

Or on Windows:

```powershell
Remove-Item -Recurse -Force "$env:USERPROFILE\.claude\skills\prompt-optimizer"
```

Any backups created by the install script (`prompt-optimizer.bak.<timestamp>/`) are left untouched — remove those too if you want a clean slate.
