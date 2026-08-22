# Changelog

All notable changes to the `prompt-optimizer` skill.
Versioning follows [Semantic Versioning](https://semver.org/):
**MAJOR** = breaking workflow change · **MINOR** = new capability · **PATCH** = fix or clarification.

## 1.0.2 — 2026-08-22

### Fixed
- Step 6 (Final Artifacts) copied the final prompt from `/tmp/final-prompt.md`, a file no earlier step ever created. It now writes `./optimized-prompt/final-prompt.md` directly via a quoted heredoc. The option to use a descriptive filename instead is unchanged.
- `install.sh` local-copy mode exited 1 (after copying `SKILL.md` but before printing the success message) when `CHANGELOG.md` wasn't beside the script — the forwarded-script case. The `CHANGELOG.md` copy is now properly optional, matching `install.ps1`.

### Changed
- SKILL.md description and intro now say "Codex CLI" instead of "Codex plugin", matching README/INSTALL and the actual `codex exec` dependency. There is no dependency on any Claude Code plugin.

## 1.0.1 — 2026-05-29

Tooling-only patch release. The skill's behavior is unchanged — only the install ergonomics differ. No need to re-clone unless you want the smarter installer.

### Changed
- `install.sh` and `install.ps1` are now three-mode installers: local-copy (run from an unzipped folder), update (re-run on an existing git checkout — does `git pull`), or fresh clone (works under `curl | sh` / `iwr | iex`).
- Re-running the install script is now the canonical update path.
- Remote one-liner installs supported via `curl ... | sh` and `iwr ... | iex`.
- Scripts refuse to touch an existing git checkout that has a non-matching `origin` remote, instead of silently overwriting.

### Added
- INSTALL.md table explaining how the install script chooses a mode.
- Troubleshooting entries for missing `git`, unfamiliar-remote refusal, and the "ran from inside the target" no-op.

## 1.0.0 — 2026-05-29

### Added
- Initial public release.
- Automated GPT review via Codex CLI (`codex exec --skip-git-repo-check`).
- Manual fallback mode for users without Codex installed.
- Iteration-2+ template that re-includes previous scores so GPT calibrates against trajectory.
- Five-signal convergence check for deciding when to stop iterating (score flattening, no new blind spots, GPT diminishing-returns flag, small targeted edits, stable rubric).
- Rubric-revision handling: re-score previous iteration under new rubric to keep the trajectory comparable.
- Evolution log written per session with heredoc-quoting pitfall documented inline.
- Final-artifacts step produces both a standalone prompt file and the evolution log.

### Notes
- Author: Yori Lavi
- Shared with a small group of friends — please send feedback or breakage reports back to me.
