# Changelog

All notable changes to the `prompt-optimizer` skill.
Versioning follows [Semantic Versioning](https://semver.org/):
**MAJOR** = breaking workflow change · **MINOR** = new capability · **PATCH** = fix or clarification.

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
