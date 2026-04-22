---
name: retrospective
description: >
  Structured project retrospective — mines the last N days of Claude Code
  sessions, audits git + plans, cross-checks epistemic layers, spawns an
  independent devil's advocate, and emits a dated retro plan into the
  project's docs/retro/. Project-agnostic — walks up from $PWD to find
  the project root (first dir containing .claude/rules/ or CLAUDE.md).
  Use when the user types /retrospective, /retro, or says "do a retro",
  "weekly retrospective", "look back on last N days", "what went wrong
  this week".
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

Walk up from `$PWD` until a directory contains `.claude/rules/` or
`CLAUDE.md`. That directory is `$PROJECT_ROOT`. If none found within
the filesystem root, error with:

```
No Claude Code project found. Run /retrospective from inside a repo
with .claude/rules/ or CLAUDE.md.
```

Cache `$PROJECT_ROOT` in `.context/retro-env.env` for reuse.

## Step 1: Environment inventory (read-only)

Gather, in parallel where possible:

1. **Git activity** (last N days):
   - `git log --since="N days ago" --oneline --stat`
   - `git status --short`
   - Count of plan files modified / added in `docs/plans/` (or project's equivalent).
2. **Claude Code setup:**
   - `ls $PROJECT_ROOT/.claude/rules/` + first 3 lines of each (titles + purpose).
   - `cat $PROJECT_ROOT/.claude/settings.json` + `settings.local.json` (allowlist size, hooks, enabledPlugins).
   - `wc -l $PROJECT_ROOT/CLAUDE.md` + top-level section list.
   - `ls ~/.claude/hooks/` (user-global hooks).
   - `ls ~/.claude/rules/` (user-global rules).
3. **Installed plugins:** read `~/.claude/settings.json` → `enabledPlugins`
   keys.

Cache the inventory to `.context/retro-inventory.md` for the plan
writer to reference.

## Step 2: Session mining

**Preferred path:** if `session-analyzer` subagent is available,
invoke it:

```
Agent({
  subagent_type: "session-analyzer",
  description: "Mine last N days of sessions",
  prompt: "Analyze Claude Code session JSONL files for this project
    from the last N days (dates: ...). Extract: friction incidents,
    codex-catches-after-harness, context gaps, permission prompts,
    plan-verify slippage, hook opportunities. Return structured JSON
    ranked by score."
})
```

**Fallback path:** raw search over JSONL files.

1. Derive project slug: replace `/` with `-` in `$PROJECT_ROOT`, prepend `-`. E.g. `/Users/me/repos/app` → `-Users-me-repos-app`.
2. Session files: `~/.claude/projects/<slug>/*.jsonl`.
3. Commands to mine:

```bash
# count user messages
jq -s 'map(select(.role=="user")) | length' ~/.claude/projects/<slug>/*.jsonl

# codex mentions
grep -c -i 'codex' ~/.claude/projects/<slug>/*.jsonl | sort -t: -k2 -n -r | head -10

# retry / correction indicators
grep -c -iE '(no|not that|stop|don'"'"'t|actually|wait)\b' ~/.claude/projects/<slug>/*.jsonl | sort -t: -k2 -n -r | head -10
```

Emit the mining output as `.context/retro-session-mining.md`.

## Step 3: Cross-check against the 3-layer epistemic model

The blognot.co 3-layer model:

- **Layer 1** — SessionStart hook injecting temporal-context (date, cutoff gap, high-risk libs).
- **Layer 2** — epistemic rules (e.g., `~/.claude/rules/epistemic.md`) with VERIFIED / FROM TRAINING / UNCERTAIN tagging.
- **Layer 3** — mandatory doc-fetch triggers (e.g., `ctx7` rule) for library docs.

Check each layer's presence. Output a table in the retro plan:

| Layer | Present? | Notes |
|---|---|---|
| L1 SessionStart temporal-context | ✅/❌ | path + status |
| L2 Epistemic rules | ✅/❌ | path |
| L3 Doc-fetch triggers | ✅/❌ | path |

## Step 4: Draft the retro plan

Produce a plan with these sections (mirror the phoneapp 2026-04-22 retro
as the template):

1. **Context** — why this retro, what prompted it, the lookback period.
2. **What already exists** — inventory from step 1 (rules, hooks, skills, plugins). Prevents "reinvent-the-wheel" mistakes.
3. **What the retrospective found** — ranked by cost. Pull from step 2 (session mining).
4. **Why it happened** — root-cause category (process gap, source-of-truth split, missing failure-path handling, etc.).
5. **Recommended setup changes** — new rules, hook opportunities, new skills, CLAUDE.md edits. Explicitly mark what's already covered by existing mechanisms.
6. **Files to create / modify** — two tables, one per repo (target project + skill-arsenal).
7. **Verification** — measurable success criteria for the changes.

Write to `.context/retro-draft.md` for the next step.

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

- `skill-arsenal/plugins/devil-advocate/` — the adversarial reviewer.
- `skill-arsenal/plugins/go/` — the full pipeline that executes retro recommendations.
- `skill-arsenal/plugins/plan-review/` — survey-style reviewer (complementary to devil-advocate).
