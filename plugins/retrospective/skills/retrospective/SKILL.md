---
name: retrospective
description: >
  Use when the user types /retrospective, /retro, or says "do a retro",
  "weekly retrospective", "look back on last N days", "what went wrong
  this week", "project retro", "sprint retrospective", or asks to
  identify repeated workflows worth packaging from recent work.
  Project-agnostic.
---

# /retrospective — structured project retrospective

Mine the project's recent activity, cross-check the current setup
against known best practices, and produce a ranked retro plan with
concrete remediation. In workflow-packaging mode, identify repeated
manual workflows worth turning into skills, custom subagents, or
automations without duplicating existing assets. Invokes
`/devil-advocate` on the draft so the output has an adversarial pass
baked in.

## Dependencies

- **Required:** `devil-advocate` skill from this marketplace.
- **Optional:** `session-analyzer` subagent. If installed and
  available, invoke it via `Agent({subagent_type: "session-analyzer"})`.
  Otherwise fall back to raw `jq`/`grep` over session JSONL.
- **Optional:** runtime-specific workflow-mining subagent. Examples:
  `codex-workflow-miner` in Codex, or `session-analyzer` in Claude.
  If installed and the user asks for repeated workflow packaging,
  delegate the read-only mining pass to it and keep asset creation in
  the parent.

## Non-negotiable guardrails

- **Project root via walk-up**, not `$PWD`. Users may invoke from
  any subdirectory.
- **Outputs to the target project's `docs/retro/`**, not skill-arsenal.
- **No mutation of product code.** Default retro writes one plan file.
  Workflow-packaging mode may modify only skill, custom-agent, or
  automation assets when the user explicitly asks to create missing
  items.
- **Scope guard:** skip if last retro in `docs/retro/` is < 7 days
  old, unless user passes `--force`.
- **Honest framing in the emitted plan.** Include a "What already
  exists" section so the plan doesn't duplicate shipped machinery.
- **No speculative packaging.** Create or extend an asset only when
  the evidence shows repeated or clearly recurring costly work,
  stable inputs, a repeatable procedure, and a clear output or stopping
  condition.

## Input contract

Accepts:

- `/retrospective` — default 7-day lookback, current project.
- `/retrospective --lookback 14` — custom lookback days.
- `/retrospective --force` — override the 7-day guard.
- `/retrospective --dry-run` — emit the plan to stdout, don't write.
- Natural-language packaging requests such as "look back over the last
  30 days and identify repeated workflows worth packaging" — run
  workflow-packaging mode. If the user also asks to create missing
  items, create only high-confidence assets after the shortlist.

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
    external-reviewer-catches-after-harness, context gaps, permission
    prompts, plan-verify slippage, hook opportunities. Return structured JSON
    ranked by score."
})
```

**Fallback path:** raw search over JSONL files.

1. Derive project slug if the active runtime uses slugged project
   folders: replace `/` with `-` in `$PROJECT_ROOT`, prepend `-`.
   E.g. `/Users/me/repos/app` → `-Users-me-repos-app`.
2. Session files: use the active runtime's session store. Common
   examples:
   - Claude Code: `~/.claude/projects/<slug>/*.jsonl`
   - Codex: `~/.codex/sessions/**/rollout-*.jsonl`,
     `~/.codex/archived_sessions/rollout-*.jsonl`, and
     `~/.codex/state_*.sqlite`
3. Commands to mine:

```bash
# count user messages
jq -s 'map(select(.role=="user")) | length' "$AGENT_HOME/projects/<slug>/"*.jsonl

# cross-runtime reviewer mentions
grep -c -iE '(codex|claude|reviewer|verifier|auditor)' "$AGENT_HOME/projects/<slug>/"*.jsonl | sort -t: -k2 -n -r | head -10

# retry / correction indicators
grep -c -iE '(no|not that|stop|don'"'"'t|actually|wait)\b' "$AGENT_HOME/projects/<slug>/"*.jsonl | sort -t: -k2 -n -r | head -10
```

Emit the mining output as `.context/retro-session-mining.md`.

For workflow-packaging mode, if a runtime-specific miner such as
`codex-workflow-miner` or `session-analyzer` is available, invoke it for
a read-only candidate pass over the requested date window. Its output is
advisory: the parent still verifies important claims against source
sessions, memories, or existing asset files before recommending or
creating anything.

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

## Step 3.5: External-reviewer feedback synthesis (Claude / Codex / senior review → agent-task-briefs)

If the project uses a junior implementation agent (worker models or junior agents) under `harness-protocol` AND any external reviewer (Claude, Codex via `/go` or `/codex`, GPT-5, senior human, or another runtime's strongest reviewer) — every catch where the reviewer found something the in-loop harness missed is a data point for the `agent-task-briefs` skill's trigger catalog.

**Required action when both conditions hold:**

1. Locate the project's reviewer-findings ledger. Common shapes:
   - `docs/retro/reviewer-findings/<period>.md` (preferred)
   - `docs/retro/codex-findings/<period>.md` (legacy / Codex-specific)
   - `audits/<date>.md`, GitHub Issues with a `caught-by-review` label, or any file with `caught_by:` provenance entries.
2. Group the lookback-period findings where `caught_by: <external-reviewer>` rows exist for the same scope as a prior in-loop pass that returned green. Cluster by failure class (client-trust, schema bounds, state drift, provider reliability, PII, lifecycle refinement, etc.).
3. For each unique class **without** an existing trigger in `agent-task-briefs/SKILL.md` § 3, propose a new trigger rule (`IF <condition> THEN <invariant + verification>`) in the draft retro under "Recommended setup changes". Cite the originating ledger entry inline so lineage is auditable.
4. For each class **with** an existing trigger that was caught again, propose a *sharpening* — narrow the condition or add a verification step. Do not duplicate.

**Why this step:** without it, the reviewer-findings ledger grows but the junior implementer keeps making the same class of mistake — the harness loop's three roles (Developer / Verifier / Auditor) share the same blind spots. Encoding catches as triggers in `agent-task-briefs` is the only mechanism that closes the loop for the **next** sprint.

**If the project doesn't yet have `agent-task-briefs` wired:** add an "Adopt agent-task-briefs skill" recommendation to the draft retro, citing the catches that motivated it. Skip this step only when no junior agent is in use.

## Step 3.6: Workflow packaging audit (only when requested)

When the user asks to find repeated manual workflows worth packaging,
apply this evidence order:

1. Recent agent sessions and task summaries (Claude, Codex, or the
   active runtime).
2. Agent memories, compaction summaries, and rollout summaries, if
   present.
3. Chronicle or other activity traces, if enabled, for discovery only.
   Confirm important details in the relevant source system.
4. Existing skills, custom agents, and automations.

Build a compact shortlist with one row per candidate:

- repeated workflow
- supporting evidence and dates
- frequency / confidence
- recommended form: skill, custom subagent, automation, extend existing, or skip
- why it is or is not worth creating

Only mark a candidate as create-worthy when all are true:

- occurred at least twice, or is clearly likely to recur and costly to repeat
- stable inputs, repeatable procedure, and clear output / stopping condition
- material speed, quality, consistency, or reliability gain
- not already adequately covered

Choose the smallest form:

- **Skill:** reusable workflow or playbook.
- **Custom subagent:** bounded specialist role or investigation task suitable for delegation.
- **Automation:** scheduled or recurring check, report, reminder, or monitor.
- **Extend existing:** a nearby skill, agent, or automation already owns the workflow.
- **Skip:** too one-off, ambiguous, sensitive, poorly evidenced, or already covered.

If the user explicitly asks to create missing items, create only
high-confidence items after the shortlist. Follow the appropriate
asset-specific workflow (`skill-creator` / `writing-skills` for skills,
custom-agent conventions for agents, automation tools for recurring
jobs). Bump plugin and marketplace versions for any skill change.

## Step 4: Draft the retro plan

Produce a plan with these sections (mirror the phoneapp 2026-04-22 retro
as the template):

1. **Context** — why this retro, what prompted it, the lookback period.
2. **What already exists** — inventory from step 1 (rules, hooks, skills, plugins). Prevents "reinvent-the-wheel" mistakes.
3. **What the retrospective found** — ranked by cost. Pull from step 2 (session mining).
4. **Why it happened** — root-cause category (process gap, source-of-truth split, missing failure-path handling, etc.).
5. **Recommended setup changes** — new rules, hook opportunities, new skills, project instructions edits. Explicitly mark what's already covered by existing mechanisms.
6. **Workflow packaging shortlist** — only in workflow-packaging mode; include create / extend / skip decisions.
7. **Files to create / modify** — two tables, one per repo (target project + skill-arsenal).
8. **Verification** — measurable success criteria for the changes.

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
blockers, path to the retro file, and top 3 recommended actions. In
workflow-packaging mode, also include what was created or extended,
what was deliberately skipped, and what needs more evidence before
packaging.

## See also

- `agent-task-briefs` — the trigger catalog that consumes findings from Step 3.5. Every retro that closes external-reviewer catches should propose a trigger-rule diff to that skill.
- `harness-protocol` — the sprint loop whose Auditor must enumerate `triggers_satisfied` from the catalog.
- `skill-arsenal/plugins/devil-advocate/` — the adversarial reviewer.
- `skill-arsenal/plugins/go/` — the full pipeline that executes retro recommendations.
- `skill-arsenal/plugins/plan-review/` — survey-style reviewer (complementary to devil-advocate).
