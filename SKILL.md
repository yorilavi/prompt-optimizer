---
name: prompt-optimizer
description: Optimizes prompts through an iterative Claude-GPT review process. Use when the user wants to optimize, improve, or refine a prompt. Supports automated review via Codex plugin or manual GPT handoff.
metadata:
  version: 1.0.0
  author: Yori Lavi
---

# Prompt Optimization Skill

> **v1.0.0** · by Yori Lavi · updated 2026-05-29 · see [CHANGELOG](./CHANGELOG.md)
> Requires: Claude Code · Optional: [Codex CLI](https://github.com/openai/codex) for automated GPT review

This skill guides an iterative prompt optimization process using both Claude and GPT as reviewers. When the Codex plugin is available, the GPT review step runs automatically — no manual copy-paste needed.

## Prerequisites Check

Before starting, detect whether Codex is available:

```bash
codex --version 2>/dev/null
```

If Codex is installed and authenticated, use **Automated Mode** (Step 3a).
If not, fall back to **Manual Mode** (Step 3b).

Inform the user which mode will be used at the start of the session.

## Process Overview

### Step 1: Get Initial Prompt
Ask the user for the prompt they want to optimize. Clarify:
- What is the prompt's purpose?
- Who/what will receive this prompt?
- What's the desired output?

### Step 2: Optimize the Prompt
Improve the initial prompt by:
- Adding clarity and specificity
- Structuring with clear sections if needed
- Removing ambiguity
- Adding constraints or guardrails
- Improving instruction flow

Present the optimized version to the user with a brief explanation of changes.

### Step 3a: GPT Review via Codex (Automated Mode)

Use `codex exec` to delegate the review to GPT. Write the review request to a temp file, then invoke Codex.

**For iteration 1 (first pass):**

```bash
cat <<'PROMPT_EOF' > /tmp/prompt-review-request.md
Please review the following original prompt and its optimized version.

**Original Prompt:**
[original prompt here]

**Optimized Prompt (by Claude):**
[optimized prompt here]

Please:
1. Review both for weaknesses, strengths, and completeness
2. Create a rubric suitable for evaluating this type of prompt
3. Score the optimized prompt against your rubric (percentage for each criterion)
4. For any criterion scoring below 85%, improve the prompt to meet that criterion
5. Explain:
   - The rubric and scoring mechanism
   - The prompt results (before and after your improvements)

Respond with the full rubric, scores, and your improved prompt version.
PROMPT_EOF

codex exec --skip-git-repo-check "$(cat /tmp/prompt-review-request.md)"
```

**For iteration 2+ (subsequent passes):** include the previous iteration's scores so GPT can calibrate against trajectory instead of starting fresh. Without this, scoring drifts between passes.

```bash
cat <<'PROMPT_EOF' > /tmp/prompt-review-request.md
Please review this iteration N of the prompt against the rubric you created previously.

Rubric (restate criteria and weights here).

Previous iteration scores:
- Iteration 1: [weighted total]% — [criteria still below threshold]
- Iteration 2: [weighted total]% — [criteria still below threshold]
...

New in this iteration vs. the version you reviewed previously:
- [change 1]
- [change 2]
...

**Prompt to review:**
[latest prompt]

Please:
1. Score this version against the rubric (weighted total + per-criterion).
2. Identify any criterion still below [95% / target] and propose a targeted fix.
3. State clearly whether further iteration is worth it or we've hit diminishing returns.
4. Only propose a full rewrite if the gap is large; targeted additions are preferred.
PROMPT_EOF

codex exec --skip-git-repo-check "$(cat /tmp/prompt-review-request.md)"
```

**Important considerations:**
- Always pass `--skip-git-repo-check` — Codex refuses to run in non-git directories without it.
- The `codex exec` output is the GPT response. Capture it for Step 4.
- **Handling large responses**: Codex output over ~10KB is persisted to a file path (shown in the Bash result as "Full output saved to: /path/...") with only a preview returned. Do NOT re-run the command. Instead, use the Read tool on that persisted path with `offset`/`limit` to slice the full response without blowing up your context.
- If `codex exec` fails or times out, inform the user and fall back to Manual Mode (Step 3b).
- Clean up the temp file after use: `rm -f /tmp/prompt-review-request.md`

After receiving the Codex/GPT response, proceed directly to Step 4 without user intervention.

### Step 3b: GPT Review (Manual Fallback)

If Codex is not available, provide the user with the review request in a code block to paste into ChatGPT:

```
Please review the following original prompt and its optimized version.

**Original Prompt:**
[original prompt here]

**Optimized Prompt (by Claude):**
[optimized prompt here]

Please:
1. Review both for weaknesses, strengths, and completeness
2. Create a rubric suitable for evaluating this type of prompt
3. Score the optimized prompt against your rubric (percentage for each criterion)
4. For any criterion scoring below 85%, improve the prompt to meet that criterion
5. Explain:
   - The rubric and scoring mechanism
   - The prompt results (before and after your improvements)
```

Tell the user: "Please paste this into ChatGPT, then paste GPT's response back here."

### Step 4: Claude Critique

After receiving GPT's response (either automatically via Codex or manually from the user), critique it structurally. Cover these four points explicitly — don't skip any:

1. **Rubric calibration** — are the weights proportional to impact? Any criterion under-weighted or over-weighted given the prompt's stated goal?
2. **Rubric blind spots** — what important dimension does the rubric fail to score at all? (Common blind spots: voice/authenticity, execution realism, sustainability, ethical risk, domain-specific failure modes.)
3. **Validity of GPT's improvements** — are the added sections genuinely load-bearing, or are they scope creep? Flag any additions that will create friction without proportional value.
4. **Claude's own additions** — propose improvements that would have significant impact: addressing a blind spot, fixing a logical flaw, meaningfully improving clarity or effectiveness. Be specific (exact language to add, where it goes). Don't just endorse GPT.

### Step 5: Iteration Check

**The numeric weighted-score delta is a tiebreaker, not the decision.** It misleads in several common cases:

- **Rubric expansion**: if GPT adds new criteria mid-process, the score can drop or stay flat even though the prompt genuinely improved (it's now being judged against harder standards).
- **Score compression at the top**: moving 96% → 96.5% looks trivial but each point in the 90s is harder-earned than a point in the 70s.
- **Qualitative step-changes**: a structural addition (e.g., Claims Ledger, Voice Fingerprint) can be transformative while barely nudging the score.
- **Scoring noise**: GPT is not a deterministic grader. Re-scoring the same prompt can vary several points from reasoning variance alone — a <1% delta may be inside the noise floor.
- **Goodharting**: optimizing to the rubric is not the same as making the prompt better. The rubric is not ground truth.

**Recommend stopping only when ALL of these converge:**

1. **Score trajectory has flattened** (small delta AND trending down across 2+ iterations).
2. **Claude's Step 4 critique finds no new blind spots** — only refinements of things already addressed.
3. **GPT explicitly states diminishing returns** in its review response.
4. **Latest additions are small targeted inserts, not new structural sections** (e.g., bullet-point additions to existing phases, not a new phase).
5. **No meaningful rubric expansion this round** — or, if there was, the prompt's score under the new rubric is stable.

If even one signal says "keep going," keep going. The right framing for the user is not "is the delta big enough?" but **"has the critique run out of substantive things to add?"**

Tell the user which signals are converging vs. still pointing to "keep going," state your recommendation, then ask explicitly: "Want to iterate once more, or finalize?"

If yes, repeat from Step 3a/3b with the latest prompt version **and include previous scores in the review request** (see Step 3a iteration 2+ template).

If no, proceed to the Final Artifacts step.

### Step 6: Final Artifacts

When the user chooses to finalize, produce **two files** (not just the evolution log):

1. **The final prompt** as a standalone file, ready to copy-paste into a fresh session:

```bash
mkdir -p ./optimized-prompt
cp /tmp/final-prompt.md ./optimized-prompt/final-prompt.md
```

(Or name it descriptively based on the prompt's purpose, e.g., `./optimized-prompt/marketing-campaign-prompt.md`.)

2. **The evolution log** (already being maintained — see below).

Tell the user both paths. The final prompt file is the one they'll actually use; the evolution log is the audit trail.

## Evolution Log

Throughout the process, maintain a running markdown file that captures every stage of the prompt's evolution. This makes it easy to review progress or present the journey in a viewer.

**At the start of the session**, create the log file. Use an unquoted heredoc for the header so `$(date ...)` interpolates correctly:

```bash
PROMPT_LOG="./prompt-evolution-$(date +%Y%m%d-%H%M%S).md"
cat > "$PROMPT_LOG" <<EOF
# Prompt Evolution Log

> Generated by the Prompt Optimizer skill
> Started: $(date '+%Y-%m-%d %H:%M:%S')

---
EOF
echo "Evolution log: $PROMPT_LOG"
```

**⚠️ Heredoc pitfall**: `<<'EOF'` (single-quoted) prevents `$(...)` expansion — timestamps come out literal. Either use unquoted `<<EOF` (but then content must be shell-safe — escape any `$`, `` ` ``, `\`) or compute the timestamp into a variable first and reference `$TS` inside a quoted heredoc:

```bash
TS="$(date '+%Y-%m-%d %H:%M:%S')"
cat >> "$PROMPT_LOG" <<EOF

## Stage N: [Stage Name]
_Timestamp: $TS_

...
EOF
```

**After each stage**, append to the log using this structure:

```markdown
## Stage N: [Stage Name]
_Timestamp: YYYY-MM-DD HH:MM:SS_

### Prompt Version
[the prompt text at this stage]

### Rubric Scores (if applicable)
| Criterion | Weight | Score | Weighted |
|---|---:|---:|---:|
| ... | ... | ... | ... |

**Weighted total: N%**

### Changes Made
[bullet list of what changed from previous version]

### Rationale
[why these changes matter]

---
```

Stage names to use:
- **Stage 1: Original Prompt** — the user's starting prompt (no changes/rationale needed)
- **Stage 2: Claude Optimization** — after Step 2
- **Stage 3: GPT Review & Rubric** — include rubric definition, scores, and GPT's improved prompt
- **Stage 4: Claude Critique** — after Step 4 (cover all four critique points)
- **Stage 5+: Iteration N — Claude Refined** / **Iteration N — GPT Review** — alternate Claude/GPT for each additional loop

### Rubric Revision Handling

If GPT proposes rubric changes mid-process (new criteria, re-weighting):

1. Log the proposed revision in the evolution log under the relevant stage ("Proposed Rubric Revision" sub-section).
2. Decide with the user whether to accept. Accept if the new criteria address genuine blind spots; reject if they're scope creep.
3. If accepted, **re-score the previous iteration under the new rubric** so the score progression stays comparable. Don't just apply the new rubric going forward — that makes the trajectory meaningless.
4. Note explicitly in the log when the rubric changed and why.

### Final Summary

At the end of the session, append a final summary:

```markdown
## Final Summary

### Final Prompt
[the final optimized prompt — also saved as a separate file per Step 6]

### Score Progression
| Iteration | Score | Key change |
|---|---:|---|
| Stage 2 | N% | [summary] |
| Stage 5 | N% | [summary] |
| ... | ... | ... |

### Key Improvements Over Original
[numbered list of the most impactful changes across all stages — focus on structural/load-bearing changes, not cosmetic]

### Rubric Scores (Final)
[table of rubric criteria and latest scores, with note if the rubric evolved during the session]

### Stopping Signals
[brief note on which convergence signals from Step 5 pointed to "stop" — for future reference]
```

Inform the user of the log file path at the start and remind them at the end. The file is self-contained markdown — viewable in any markdown previewer.

## Output Format

Always clearly label:
- **Current Version**: The prompt being reviewed
- **Proposed Changes**: What you're suggesting
- **Rationale**: Why each change matters

## Handoff Template

When using manual fallback (Step 3b), always format the text in a code block so the user can easily copy it.

## Mode Switching

If automated mode fails mid-session (e.g., Codex auth expires, rate limits hit), switch to manual mode gracefully:
1. Inform the user that Codex is temporarily unavailable
2. Provide the review request as a code block for manual paste
3. Continue the session without interruption
