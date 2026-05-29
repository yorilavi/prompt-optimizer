# Installing `prompt-optimizer`

A skill for Claude Code that runs an iterative Claude ↔ GPT review loop on any prompt and ships you an optimized version.

---

## Requirements

- **Claude Code** — CLI, VS Code extension, or JetBrains plugin. Any of them work.
- **Optional: [Codex CLI](https://github.com/openai/codex)** — enables automated GPT review. Without it, the skill falls back to a "paste this into ChatGPT" mode automatically. You do not need to install Codex to use the skill.

---

## Quick install (recommended)

Three paths. Pick whichever matches how you got here. All three end up at the same place: `~/.claude/skills/prompt-optimizer/` with `SKILL.md` and `CHANGELOG.md` in it.

### 1. `git clone` — the most transparent path

No script involved. The same command serves as the install, and `git pull` from inside the directory updates it later.

```sh
# macOS / Linux / WSL / Git Bash on Windows
git clone https://github.com/yorilavi/prompt-optimizer.git ~/.claude/skills/prompt-optimizer
```

```powershell
# Windows PowerShell
git clone https://github.com/yorilavi/prompt-optimizer.git "$env:USERPROFILE\.claude\skills\prompt-optimizer"
```

### 2. `install.sh` / `install.ps1` — one command that handles every install state

Use this when you've already got the script locally — from an unzipped archive, a friend's forward, or a previous install you want to update. It auto-detects which mode applies.

```sh
sh install.sh                                                # macOS / Linux / WSL / Git Bash
```

```powershell
powershell -ExecutionPolicy Bypass -File .\install.ps1       # Windows
```

How the script decides what to do:

| Situation | What runs |
|---|---|
| Script sits next to a `SKILL.md` (you unzipped the archive) | **Local copy** — copies `SKILL.md` + `CHANGELOG.md` to the target. |
| `~/.claude/skills/prompt-optimizer/.git` exists with the right remote | **Update** — runs `git pull --ff-only` in place. |
| Neither of the above (forwarded script, `curl | sh`, fresh machine) | **Clone** — `git clone --depth 1` from GitHub into the target. |
| `~/.claude/skills/prompt-optimizer/.git` exists but the remote is something else | **Refuses.** Won't touch a checkout it doesn't recognize. Move it aside and re-run. |

Any pre-existing non-git install at the target is backed up to `prompt-optimizer.bak.<unix-timestamp>` before being replaced — no silent overwrites. Re-running the script is the canonical way to update.

### 3. One-line remote install

Pipes the script straight from GitHub. Convenient, but `curl | sh` is a trust call you should make consciously — read the script first if you're unsure.

```sh
curl -fsSL https://raw.githubusercontent.com/yorilavi/prompt-optimizer/main/install.sh | sh
```

```powershell
iwr -useb https://raw.githubusercontent.com/yorilavi/prompt-optimizer/main/install.ps1 | iex
```

Skip to [Verify the install](#verify-the-install) once any of these finishes.

---

## Manual install (from a zip)

Use this path if you've been sent a zip and want to copy the files into place by hand instead of running a script.

> If you don't have a zip but you do have git, the `git clone` option in [Quick install](#1-git-clone--the-most-transparent-path) is simpler — one command, no manual file moving, and `git pull` updates you later.

### Step 0 — get the files

You need an unzipped copy of the skill on disk before any of the commands below will work.

- **Official zip:** grab "Source code (zip)" from the [latest release page](https://github.com/yorilavi/prompt-optimizer/releases/latest).
  Direct link to the current release archive: <https://github.com/yorilavi/prompt-optimizer/archive/refs/tags/v1.0.1.zip>
- **From a friend:** use whichever zip they sent.

Unzip it. GitHub's release archive extracts to a folder named `prompt-optimizer-1.0.1/` (with the version suffix). A friend's zip might extract to `prompt-optimizer/`. **The folder you place under `~/.claude/skills/` must be named exactly `prompt-optimizer/`** — rename or `cp` accordingly. The commands below assume that.

### macOS / Linux

```sh
# From the directory that contains the unzipped folder:
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
# From the directory that contains the unzipped folder:
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
The script no-ops if you ran it from inside `~/.claude/skills/prompt-optimizer/` itself (the author's dev case). It prints a hint to use `git pull` there instead. Run the script from `Downloads/` or anywhere outside the target if you want it to install or update for you.

**The script says "git is required but was not found on PATH."**
Two of the three install paths (clone, update) need git. Install it from <https://git-scm.com/downloads>, then re-run. The local-copy path (running the script from an unzipped folder that contains `SKILL.md`) doesn't need git.

**The script refuses with "existing git checkout has an unfamiliar remote."**
Something at `~/.claude/skills/prompt-optimizer/` is a git checkout, but its `origin` doesn't point at `yorilavi/prompt-optimizer`. The script won't touch it. Either move that directory aside and re-run, or `cd` into it and fix the remote yourself.

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
