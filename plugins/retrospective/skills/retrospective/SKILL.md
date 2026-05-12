---
name: retrospective
description: >
  Use when the user types /retrospective, /retro, or says "do a retro",
  "weekly retrospective", "look back on last N days", "what went wrong
  this week", "project retro", "sprint retrospective". Emits a dated
  retro plan into docs/retro/. Project-agnostic.
---

# /retrospective — structured project retrospective

Mine the project's recent activity, cross-check the current setup
against known best practices, and produce a ranked retro plan with
concrete remediation. Invokes `/devil-advocate` on the draft so the
output has an adversarial pass baked in.

## Dependencies

- **Required:** `devil-advocate` skill from this marketplace.
- **Optional:** `session-analyzer` subagent. If installed and
  available, invoke it via `Agent({subagent_type: "session-analyzer"})`.
  Otherwise fall back to raw `jq`/`grep` over session JSONL.

## Non-negotiable guardrails

- **Project root via walk-up**, not `$PWD`. Users may invoke from
  any subdirectory.
- **Outputs to the target project's `docs/retro/`**, not skill-arsenal.
- **No mutation of the project's code.** Retro writes one plan file.
- **Scope guard:** skip if last retro in `docs/retro/` is < 7 days
  old, unless user passes `--force`.
- **Honest framing in the emitted plan.** Include a "What already
  exists" section so the plan doesn't duplicate shipped machinery.

## Input contract

Accepts:

- `/retrospective` — default 7-day lookback, current project.
- `/retrospective --lookback 14` — custom lookback days.
- `/retrospective --force` — override the 7-day guard.
- `/retrospective --dry-run` — emit the plan to stdout, don't write.

## Step 0: Project root discovery (do this first, cache results)

Walk up from `$PWD` until a directory contains one of: `AGENTS.md`,
`CLAUDE.md`, `.claude/rules/`, `.codex/rules/`, `.git/`, or another
runtime-specific project instruction file. That directory is `$PROJECT_ROOT`.
If none is found before the filesystem root, error with:

```
No agent project found. Run /retrospective from inside a repo
with AGENTS.md, CLAUDE.md, .claude/rules/, .codex/rules/, or .git/.
```

Cache `$PROJECT_ROOT` in `.context/retro-env.env` for reuse.

## Step 1: Environment inventory (read-only)

Gather, in parallel where possible:

1. **Git activity** (last N days):
   - `git log --since="N days ago" --oneline --stat`
   - `git status --short`
   - Count of plan files modified / added in `docs/plans/` (or project's equivalent).
2. **Agent setup:**
   - Detect project instruction files (`AGENTS.md`, `CLAUDE.md`, or runtime equivalent).
   - Detect project rule directories (`.claude/rules/`, `.codex/rules/`, or runtime equivalent).
   - Detect runtime settings files when present.
   - Detect user-global hooks and rules for the active runtime.
3. **Installed plugins:** read the active runtime's settings or marketplace
   metadata when available.

Cache the inventory to `.context/retro-inventory.md` for the plan
writer to reference.

## Step 2: Session mining

**Preferred path:** if `session-analyzer` subagent is available,
invoke it:

```
Agent({
  subagent_type: "session-analyzer",
  description: "Mine last N days of sessions",
  prompt: "Analyze agent session JSONL files for this project
    from the last N days (dates: ...). Extract: friction incidents,
    codex-catches-after-harness, context gaps, permission prompts,
    plan-verify slippage, hook opportunities. Return structured JSON
    ranked by score."
})
```

**Fallback path:** raw search over JSONL files.

1. Derive project slug: replace `/` with `-` in `$PROJECT_ROOT`, prepend `-`. E.g. `/Users/me/repos/app` → `-Users-me-repos-app`.
2. Session files: `$AGENT_HOME/projects/<slug>/*.jsonl`, where
   `$AGENT_HOME` is the active runtime's session directory.
3. Commands to mine:

```bash
# count user messages
jq -s 'map(select(.role=="user")) | length' "$AGENT_HOME/projects/<slug>/"*.jsonl

# codex mentions
grep -c -i 'codex' "$AGENT_HOME/projects/<slug>/"*.jsonl | sort -t: -k2 -n -r | head -10

# retry / correction indicators
grep -c -iE '(no|not that|stop|don'"'"'t|actually|wait)\b' "$AGENT_HOME/projects/<slug>/"*.jsonl | sort -t: -k2 -n -r | head -10
```

Emit the mining output as `.context/retro-session-mining.md`.

## Step 3: Cross-check against the 3-layer epistemic model

The blognot.co 3-layer model:

- **Layer 1** — SessionStart hook injecting temporal-context (date, cutoff gap, high-risk libs).
- **Layer 2** — epistemic rules (for example `$AGENT_HOME/rules/epistemic.md`) with VERIFIED / FROM TRAINING / UNCERTAIN tagging.
- **Layer 3** — mandatory doc-fetch triggers (e.g., `ctx7` rule) for library docs.

Check each layer's presence. Output a table in the retro plan:

| Layer | Present? | Notes |
|---|---|---|
| L1 SessionStart temporal-context | ✅/❌ | path + status |
| L2 Epistemic rules | ✅/❌ | path |
| L3 Doc-fetch triggers | ✅/❌ | path |

## Step 3.5: External-reviewer feedback synthesis (Codex / senior review → agent-task-briefs)

If the project uses a junior implementation agent (worker models or junior agents) under `harness-protocol` AND any external reviewer (Codex via `/go` or `/codex`, GPT-5, senior human) — every catch where the reviewer found something the in-loop harness missed is a data point for the `agent-task-briefs` skill's trigger catalog.

**Required action when both conditions hold:**

1. Locate the project's reviewer-findings ledger. Common shapes:
   - `docs/retro/codex-findings/<period>.md` (skill-arsenal default)
   - `audits/<date>.md`, GitHub Issues with a `caught-by-review` label, or any file with `caught_by:` provenance entries.
2. Group the lookback-period findings where `caught_by: <external-reviewer>` rows exist for the same scope as a prior in-loop pass that returned green. Cluster by failure class (client-trust, schema bounds, state drift, provider reliability, PII, lifecycle refinement, etc.).
3. For each unique class **without** an existing trigger in `agent-task-briefs/SKILL.md` § 3, propose a new trigger rule (`IF <condition> THEN <invariant + verification>`) in the draft retro under "Recommended setup changes". Cite the originating ledger entry inline so lineage is auditable.
4. For each class **with** an existing trigger that was caught again, propose a *sharpening* — narrow the condition or add a verification step. Do not duplicate.

**Why this step:** without it, the reviewer-findings ledger grows but the junior implementer keeps making the same class of mistake — the harness loop's three roles (Developer / Verifier / Auditor) share the same blind spots. Encoding catches as triggers in `agent-task-briefs` is the only mechanism that closes the loop for the **next** sprint.

**If the project doesn't yet have `agent-task-briefs` wired:** add an "Adopt agent-task-briefs skill" recommendation to the draft retro, citing the catches that motivated it. Skip this step only when no junior agent is in use.

## Step 4: Draft the retro plan

Produce a plan with these sections (mirror the phoneapp 2026-04-22 retro
as the template):

1. **Context** — why this retro, what prompted it, the lookback period.
2. **What already exists** — inventory from step 1 (rules, hooks, skills, plugins). Prevents "reinvent-the-wheel" mistakes.
3. **What the retrospective found** — ranked by cost. Pull from step 2 (session mining).
4. **Why it happened** — root-cause category (process gap, source-of-truth split, missing failure-path handling, etc.).
5. **Recommended setup changes** — new rules, hook opportunities, new skills, project instructions edits. Explicitly mark what's already covered by existing mechanisms.
6. **Files to create / modify** — two tables, one per repo (target project + skill-arsenal).
7. **Verification** — measurable success criteria for the changes.

Write to `.context/retro-draft.md` for the next step.

## Step 4.5: Proportionality pass (calibrate against adoption)

`/devil-advocate` (the next step) sharpens findings — it does not size them.
A retro that proposes 12 process additions is not better than one that
proposes 3 *that the team will actually adopt and enforce*. Adversarial
pressure without proportionality calibration produces rule-bloat: rules
that read well on the day they're written and silently get skipped a
week later.

For each item in the draft's **"Recommended setup changes"** section, score on two axes:

- **Adoption likelihood (0–3)** — given the project's recent track record, will this rule survive 30 days? Evidence: how many existing project rules (`.claude/rules/`, `.codex/rules/`, or runtime equivalent) were violated in the lookback window's session mining (already gathered in step 2)? A rule similar in shape to one that was repeatedly violated should score low.
- **Failure-prevention value (0–3)** — does this rule actually stop the failure mode it targets, or merely document it? Heuristic, strongest first:
  1. **Tooling-enforced** — hook, CI gate, lint, test (3).
  2. **Rule-with-trigger** — `paths:` frontmatter, command rule (2).
  3. **Documentation** — "remember to do X before Y" (1).
  4. **Convention** — "we should…" (0).

For each recommendation, compute `score = adoption × value`. Apply:

- `score ≥ 6` → keep as-is, promote in the final retro.
- `3 ≤ score < 6` → keep, but downgrade to the strongest mechanism the project can sustain (e.g., turn a "rule" into a "hook" or drop a multi-step protocol into a single line of project instructions).
- `score < 3` → move to a new **"Considered and rejected"** appendix in the draft, with a one-line note explaining the score. The analysis is preserved; the rule isn't shipped.

The output of step 4.5 is the same draft file (`.context/retro-draft.md`) with the Recommended-setup-changes section rewritten and the Considered-and-rejected appendix added. **Step 5 (`/devil-advocate`) then runs against this calibrated draft, not the raw one.**

This step is intentionally not adversarial. Its job is to ask "is this proportionate?" — a question `/devil-advocate` is the wrong tool to answer because adversarial review by construction wants more rules, not fewer.

## Step 5: Invoke /devil-advocate on the draft

Slash-command invocation (not programmatic Agent call):

```
/devil-advocate \
  --target <$PROJECT_ROOT>/.context/retro-draft.md \
  --attack "hook mechanics, skill discovery, rule loading, subagent format, measurement rigor, scope creep" \
  --word-cap 700
```

The devil-advocate output is appended to the draft as a new section
"Devil's-advocate pass — findings incorporated." For each BLOCKER or
MAJOR finding, apply the suggested edit to the draft before emitting.

## Step 6: Emit the final retro plan

Write to `<$PROJECT_ROOT>/docs/retro/YYYY-MM-DD-<slug>.md` where
`<slug>` is a short kebab-case description of the retro focus (e.g.,
`2026-04-22-retro-codex-left-and-rules`).

Commit the retro file to the current branch with message:

```
docs(retro): YYYY-MM-DD retrospective — <slug>

Mined <N> sessions, identified <K> findings, devil-advocate reviewed.
Plan covers <topic list>.
```

## Step 7: Report

Emit a concise summary to the user: number of findings, number of
blockers, path to the retro file, and top 3 recommended actions.

## See also

- `agent-task-briefs` — the trigger catalog that consumes findings from Step 3.5. Every retro that closes external-reviewer catches should propose a trigger-rule diff to that skill.
- `harness-protocol` — the sprint loop whose Auditor must enumerate `triggers_satisfied` from the catalog.
- `skill-arsenal/plugins/devil-advocate/` — the adversarial reviewer.
- `skill-arsenal/plugins/go/` — the full pipeline that executes retro recommendations.
- `skill-arsenal/plugins/plan-review/` — survey-style reviewer (complementary to devil-advocate).
