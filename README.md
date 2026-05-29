# prompt-optimizer

A Claude Code skill that runs an iterative review loop between two language models — Claude and GPT — to optimize a prompt. The point isn't the loop. The point is what the loop *forces the models to do*.

---

## The idea

Most LLM-on-LLM review is noisy. Ask one model to grade another model's work and you get plausible feedback that often disagrees with what a third model would say, because **every model is silently using its own definition of "great."** Their disagreement isn't a sign one of them is wrong. It's a sign they aren't actually talking about the same thing.

This skill makes that disagreement productive by forcing both models to externalize their evaluation criteria into a shared, weighted **rubric** — and then treats *that rubric* as the primary artifact under iteration, not the prompt.

The loop, in one breath:

```
Round N:
   Prompt vN   ─►   Claude: optimize
                       │
                       ▼
                    GPT: build/refine the rubric, then score the prompt against it
                       │
                       ▼
                    Claude: critique the rubric — what is it failing to measure?
                       │
                       ▼
   Prompt vN+1 + Rubric vN+1     ─►   next round
```

The rubric is the common language. Without it, the two models are passing each other in the dark. With it, they can actually disagree about something specific, fix that specific thing, and converge on a definition of "great" that neither would have written alone.

## Why this works (and why simpler loops don't)

If you only iterate the **prompt** and never the **criteria**, you're hill-climbing on a gradient that one of the models invented in its head and never revealed. Each round drifts. The score wobbles. You can't tell if you're improving or just rewording.

If you iterate the **rubric** too, three useful things happen at once:

1. **The criteria sharpen.** Each round of critique surfaces a dimension that was missing or under-weighted (voice, execution realism, hidden assumptions, the failure mode a specific user type would hit). You leave the session not just with a better prompt, but with a better *evaluation framework* for prompts of this type — reusable for the next one.

2. **The models start solving the same problem.** Once both Claude and GPT agree on what they're measuring, their scores become legible. A 92 in round three means something a 92 in round one didn't. Disagreements between them now point at real gaps, not vibes.

3. **You exit metacognition.** This is the actual lever. The skill isn't asking the models to "improve the prompt." It's asking them to expose, examine, and refine how *they themselves* judge prompts — what they notice, what they ignore, what they weight, what they miss. The prompt improvement is downstream of that.

The trap to avoid: optimizing the prompt to the rubric. The rubric is not ground truth. It's the working hypothesis of what matters. When a round produces a higher score but a worse prompt, that's the rubric telling you it's the one that needs work — not the prompt.

## Install

One-liner — clones the repo straight into Claude Code's skills directory.

**macOS / Linux / WSL / Git Bash on Windows:**

```sh
git clone https://github.com/yorilavi/prompt-optimizer.git ~/.claude/skills/prompt-optimizer
```

**Windows PowerShell:**

```powershell
git clone https://github.com/yorilavi/prompt-optimizer.git "$env:USERPROFILE\.claude\skills\prompt-optimizer"
```

Restart Claude Code. Verify it loaded with `/skills` — you should see `prompt-optimizer` in the list.

Detailed install (including manual copy, troubleshooting, uninstall): see [INSTALL.md](./INSTALL.md).

## Usage

In any Claude Code session:

```
/prompt-optimizer
```

Or describe what you want:

> "Use the prompt optimizer to improve this prompt for cold outreach: …"

The skill walks you through:

1. **Stating the prompt** and its purpose.
2. **Initial optimization** by Claude.
3. **Rubric construction + scoring** by GPT (automated via the [Codex CLI](https://github.com/openai/codex) if installed; otherwise a copy-paste handoff to ChatGPT).
4. **Critique** by Claude — explicitly four-part: rubric calibration, rubric blind spots, validity of GPT's improvements, Claude's own additions.
5. **Convergence check** against five signals — not the score delta, which is a tiebreaker, not the decision.
6. **Final artifacts**: a standalone optimized prompt file, plus an evolution log capturing every round.

## Stopping

The skill recommends stopping only when **all five** of these converge in the same round:

- Score trajectory has flattened and is trending down (you're past the peak).
- Claude's critique finds no new blind spots — only refinements of things already addressed.
- GPT explicitly flags diminishing returns.
- The latest additions are small targeted edits, not new structural sections.
- The rubric is stable (no new criteria; no re-weighting).

If even one signal says "keep going," keep going. The right framing isn't "is the delta big enough?" — it's **"has the critique run out of substantive things to add?"**

## Requirements

- **Claude Code** — CLI, VS Code extension, or JetBrains plugin.
- **Optional: [Codex CLI](https://github.com/openai/codex)** — enables automated GPT review. Without it, the skill falls back to a manual copy-paste handoff with ChatGPT. You don't need Codex to use the skill.

## Updates

```sh
cd ~/.claude/skills/prompt-optimizer && git pull
```

Subscribe to releases at the [repo page](https://github.com/yorilavi/prompt-optimizer) for change notifications.

See [CHANGELOG.md](./CHANGELOG.md) for the version history.

## Author

**Yori Lavi** · current version: **v1.0.0**

Issues and suggestions: open one on the [repo](https://github.com/yorilavi/prompt-optimizer/issues), or DM me directly if you got this skill from me.
