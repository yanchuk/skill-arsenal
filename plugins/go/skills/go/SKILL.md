---
name: go
description: >
  Use when the user types `/go`, `/go <task>`, or says "go", "full pipeline",
  "do the whole thing", "ship this end to end", "run the full flow", or is
  ready to hand off a complete product-level task for autonomous execution.
  Runs an autonomous multi-phase pipeline inside an isolated worktree —
  phases defined in the skill body. Project-agnostic.
---

# /go — full-lifecycle feature pipeline

Run a complete product-level task from **plan → execute → audit → done** with
zero user intervention between phases. The task comes from the conversation or
the `/go <task>` argument. If the task is ambiguous, ask ONE clarifying
question before starting — after that, execute silently.

## Dependencies (other skills invoked)

- `harness-protocol` — required. Loaded from this same arsenal. `/go` is the Orchestrator described there.
- `superpowers:writing-plans`, `superpowers:executing-plans`, `superpowers:test-driven-development`, `superpowers:dispatching-parallel-agents`, `superpowers:subagent-driven-development`.
- `plan-review` — from this arsenal.
- `simplify` — any implementation available in the environment (e.g., gstack).
- `codex` — for plan audit and final audit. **Optional.** If the Codex CLI is not available, is not authenticated, or fails a smoke check, `/go` skips phases 6, 7, 11, and 12's Codex call and logs a note in the plan's "Rejected final-audit findings" section so the omission is explicit.

## Non-negotiable guardrails

- **All work happens in a new git worktree** under `~/.claude/worktrees/` with a descriptive kebab-case name derived from the task. Never work on the default branch directly.
- **Every phase produces a commit.** Never squash phases together.
- **Codex thread is reused across the two Codex passes** (plan review + final review). Persist the session id to `.context/codex-session-id` between calls and resume via `codex exec resume <session-id>`.
- **Harness is orchestrator-owned** (see `harness-protocol`). `/go` spawns Developer → Verifier → Auditor sub-agents per sprint. No sub-agent plays two roles. No self-evaluation. No batched sprints.
- **Parallelism only where truly independent.** Cross-sprint: serial. Intra-sprint triad: serial. Within a single role, independent subtasks may fan out via `superpowers:dispatching-parallel-agents`.
- **Never bypass hooks or test gates** (`--no-verify`, `SKIP_E2E=1`, etc.) unless the user explicitly authorizes it for a docs-only change.
- When Codex raises a finding, **validate it against the actual code** before acting. Fabricated/stale findings get documented as rejected with reasoning; real ones get fixed in their own commits.

## Model tiering (Opus vs Sonnet inside `/go`)

Sub-agents spawned by `/go` do not all need the same model. Tier by role, not by phase. The hard rule: **the Auditor must never be tiered down**. The harness's >9/10 gate is what protects every sprint downstream; degrading the gate degrades the protocol.

| Sub-agent role | Phases | Model |
|---|---|---|
| `superpowers:writing-plans` author | 2 | Opus — wrong-shape plan poisons all downstream phases |
| `plan-review` reviewer | 4 | Opus — same poison-the-well risk |
| Codex-finding validator (`Explore`) | 7, 12 | Sonnet — narrow, evidence-based per finding |
| **Developer** | 8 | **Mixed** — see decision rule below |
| **Verifier** | 8 | Sonnet — structured PASS/FAIL with evidence; mechanical |
| **Auditor** | 8, 12-mini | **Opus — non-negotiable.** Long-context skeptical grading is the protocol's quality multiplier |
| `simplify` pass | 9 | Sonnet |
| Ledger promotion | 13 | Sonnet (or deterministic shell) |

**Developer decision rule.** Use Opus when the sprint touches:

- Any path the project marks as E2E-mandatory (read `.claude/rules/testing-gates.md`).
- Any new abstraction, new module, or refactor crossing >5 files.
- Any money / auth / state-transition / migration change.

Otherwise use Sonnet.

**Spawn instructions.** When spawning sub-agents in phases 7, 8, 9, 12, and 13, pass an explicit `model:` parameter to `Agent()` per the table above. Do not rely on the inherited model — the parent is usually Opus, and inheriting silently defeats the tiering. If `Agent()` does not accept a `model:` field in the runtime you're on, use `subagent_type` to pick an agent variant whose definition pins the right model.

**Why this is safe.** With the Auditor still on Opus, Sonnet errors at the Verifier or Developer level get caught and bounced back as a fix loop. Net effect across a 4-sprint task: roughly one extra fix loop, but each loop is faster + ~3–5× cheaper. Realistic wall-clock improvement: 25–35% end-to-end. The savings disappear if you tier down the Auditor.

## Project discovery (do this first, cache results)

On startup `/go` discovers project conventions. Detect and remember:

| Need | Discovery order |
|------|-----------------|
| **Verification gate command** | `.claude/rules/testing-gates.md` → `package.json` scripts (`verify`, `verify:wave`, `ci`, `check`, `test:all`) → `Makefile` (`verify`, `ci`, `check`) → language default (see `harness-protocol`). |
| **Unit-test command** | `package.json` `test` → `Makefile test` → language default. |
| **Typecheck command** | `package.json` `typecheck` / `tsc --noEmit` → `mypy` / `pyright` → `tsc`. Skip silently if not applicable. |
| **E2E command** | `package.json` `playwright*` / `e2e*` → language default → skip if no E2E infra. |
| **E2E-mandatory paths** | `.claude/rules/testing-gates.md` → fall back to: any user-facing route, any money/auth/state transition, any file that imports a payment/auth SDK. |
| **Plans directory** | `docs/plans/` → `plans/` → `.plans/` → create `docs/plans/` if none. |
| **Default branch** | `git symbolic-ref refs/remotes/origin/HEAD` → `origin/main` → `origin/master`. |
| **Plan file naming** | `<plans-dir>/YYYY-MM-DD-<slug>.md`. |

Record discoveries to `.context/go-env.json` for reuse across phases.

### Codex readiness probe (do this during discovery)

Goal: decide whether Codex is usable, without false-negative-ing on a cold start. A cold Codex (auth refresh + model warm-up) routinely needs 30–60s before the first streaming event. Do NOT fail the probe just because the first HTTP call is slow. The rule: **Codex is alive as soon as a `thread.started` event appears in the JSON stream.** If nothing arrives within the probe timeout, treat it as unavailable.

```bash
CODEX_OK=no
if command -v codex >/dev/null 2>&1 && timeout 15 codex --version >/dev/null 2>&1; then
  # Probe: up to 120s wall-clock. Declare alive as soon as thread.started
  # is seen on stdout — don't wait for the full reply.
  PROBE_OUT=$(mktemp)
  ( timeout 120 codex exec "ping" -s read-only --json 2>/dev/null \
      | tee "$PROBE_OUT" >/dev/null ) &
  PROBE_PID=$!
  for _ in $(seq 1 24); do  # ~120s, checking every 5s
    if grep -q '"type":"thread.started"' "$PROBE_OUT" 2>/dev/null; then
      CODEX_OK=yes
      break
    fi
    kill -0 "$PROBE_PID" 2>/dev/null || break
    sleep 5
  done
  # Whether alive or dead, reap the probe.
  kill "$PROBE_PID" 2>/dev/null; wait "$PROBE_PID" 2>/dev/null
  rm -f "$PROBE_OUT"
fi
echo "CODEX_OK=$CODEX_OK" >> .context/go-env.env
```

If `CODEX_OK=no`:
- Skip phases 6, 7, 11, and the Codex half of phase 12.
- Keep all other phases (harness execution is independent of Codex).
- In phase 13's summary, note `codex: unavailable — plan and final reviews skipped` so the user knows what didn't run.
- Do **not** fail the pipeline because Codex is missing. Codex is a second-opinion accelerant, not a gate.

## Input contract — what /go expects and what it produces

**Input (one of):**
- a task description in the message (e.g., "/go add X");
- an upstream PM/brief/story document (path passed in the message, or most recent file under `~/.claude/plans/` if the user points there);
- a list of user stories with acceptance criteria.

Whatever form the input takes, treat it as **stories + intent** — not as a detailed engineering plan. The PM spec answers *what the user wants*; /go is responsible for answering *how we build and verify it*.

**Output:** a detailed engineering plan at `<plans-dir>/YYYY-MM-DD-<slug>.md` authored by `superpowers:writing-plans`, hardened by `plan-review` and Codex, then executed under the harness.

**Hard rule:** Phase 2 always invokes `superpowers:writing-plans`. Do NOT skip writing-plans in favor of `cp`-ing an upstream plan into `docs/plans/`, even when the upstream plan looks complete. When an upstream doc exists, pass its path as input context to writing-plans (e.g., "draft a detailed engineering plan for the user stories in `<path>`") so writing-plans can derive engineering scope, guardrails, edge cases, and files-to-modify from it. The resulting plan file is what phase 5 commits and what phases 6–12 review, audit, and implement against.

## Execution sequence

Use `TaskCreate` up front to materialize **all fourteen phases as separate todos** so the user can watch progress. Mark each completed as you go.

**Anti-bundling rule:** Phases 2, 3, 4, and 5 are four distinct todos and four distinct commits. Never merge them — especially not when an upstream PM plan exists. `plan-review` (phase 4) pauses for `AskUserQuestion` and must be visible in the task list so the user can see it ran; if it is bundled into an adjacent todo it gets skipped silently. `writing-plans` (phase 2) must be visible for the same reason — a task labeled "Copy plan" signals that the skill skipped its own authoring step.

The fourteen TaskCreate items (use these labels verbatim — do not invent shorter or combined labels):

1. Phase 1 — Setup worktree + project discovery + Codex readiness probe
2. Phase 2 — writing-plans skill pass (detailed engineering plan)
3. Phase 3 — Append Harness Protocol section
4. Phase 4 — plan-review skill pass (auto-accept recommended options)
5. Phase 5 — Commit the plan
6. Phase 6 — Codex plan review (skip if unavailable)
7. Phase 7 — Validate + apply Codex plan findings (skip if unavailable)
8. Phase 8 — Execute sprints under harness protocol
9. Phase 9 — Simplify pass
10. Phase 10 — Clean tree + shipping gate
11. Phase 11 — Final Codex audit (skip if unavailable)
12. Phase 12 — Validate + fix final-audit findings (skip if unavailable)
13. Phase 13 — Promote open findings to monthly ledger (skip if no project ledger directory)
14. Phase 14 — Done — print summary

### 1. Setup worktree

```bash
TASK_SLUG="<kebab-case-slug>"
DEFAULT_BRANCH="$(git symbolic-ref --short refs/remotes/origin/HEAD 2>/dev/null | sed 's@^origin/@@' || echo main)"
WT=~/.claude/worktrees/$TASK_SLUG
git fetch origin "$DEFAULT_BRANCH"
git worktree add "$WT" -b "$TASK_SLUG" "origin/$DEFAULT_BRANCH"
cd "$WT"
mkdir -p .context
```

All file edits below happen inside `$WT`. Every shell command either uses an absolute path or is prefixed with `cd "$WT" && …`.

### 2. Write the plan (always via writing-plans — never by copying)

Invoke `Skill` → `superpowers:writing-plans`. Input to writing-plans:

- If the message contains an upstream PM/brief/story doc path, pass that path plus the user's task description as context — writing-plans reads it and derives the engineering plan from it. Do NOT `cp` the upstream doc into `<plans-dir>/` as a substitute for running writing-plans.
- If no upstream doc exists, pass just the task description.

The output engineering plan must cover: scope, acceptance criteria (each tied back to a user story if stories exist), guardrails, edge cases, and files to modify. Write the plan to `<plans-dir>/YYYY-MM-DD-<slug>.md`. Phases 3–5 mutate and commit this same file.

### 3. Add Harness Protocol section

Append a **Harness Protocol** section to the plan that lists the sprints and — for each sprint — Developer / Verifier / Auditor responsibilities per the `harness-protocol` skill in this arsenal. Every sprint gets explicit acceptance criteria and a ≥9/10 threshold per criterion.

### 4. Plan review — auto-accept recommended options

Invoke `Skill` → `plan-review`. When it asks for decisions, accept **every recommended option** unless it contradicts a documented project rule (CLAUDE.md, `.claude/rules/`). Fold the output back into the plan file.

### 5. Save + commit the plan

```bash
PLAN="<plans-dir>/$(date +%Y-%m-%d)-$TASK_SLUG.md"
git add "$PLAN"
git commit -m "docs(plans): $TASK_SLUG — initial plan"
```

### 6. Codex plan review (capture session id for reuse) — **skip if `CODEX_OK=no`**

**Execution mechanics (important — prevents premature "Codex unavailable"):**

- Run the Codex call below via Bash with `run_in_background: true`. The Bash tool's default 120s timeout will kill a legitimate Codex review on a real plan — do not use the foreground Bash path for this step.
- Simultaneously, poll `.context/codex-plan-review.jsonl` every 30s for either:
  - a new `item.completed` or `agent_message` event (Codex is producing output — keep waiting), or
  - a `thread.completed` / process-exit (Codex is done — move on).
- If no new JSON event appears for **three consecutive polls (90s of silence)** and the process has not exited, treat it as hung: kill the background job, mark Codex unavailable for this phase only, and proceed to phase 8. Record the skip reason in the plan's "Rejected Codex findings" section.
- If you ever need a single foreground fallback, pass `timeout: 600000` (10 min) to the Bash tool.

Same rule applies to phase 11.

```bash
TMPERR=$(mktemp)
codex exec "Critically review $PLAN. \
IMPORTANT: Do NOT read or execute any files under ~/.claude/, ~/.agents/, \
.claude/skills/, or agents/. Focus on plan correctness, completeness, \
edge-cases, risks, testability." \
  -C "$(pwd)" -s read-only -c 'model_reasoning_effort="high"' \
  --enable web_search_cached --json 2>"$TMPERR" \
| tee .context/codex-plan-review.jsonl \
| python3 -c "
import sys, json
for line in sys.stdin:
    try: obj = json.loads(line)
    except: continue
    t = obj.get('type','')
    if t == 'thread.started':
        open('.context/codex-session-id','w').write(obj.get('thread_id',''))
    if t in ('item.completed','agent_message'):
        m = obj.get('item',{}).get('text') or obj.get('message','')
        if m: print(m)
"
```

### 7. Validate + apply Codex plan findings (parallel fan-out) — **skip if `CODEX_OK=no`**

If Codex returns multiple independent findings, fan them out with `superpowers:dispatching-parallel-agents` — one `Explore` sub-agent per finding, each returning `{finding, valid, evidence: file:line, proposed_patch}`. Merge serially: valid → amend plan; invalid → "Rejected Codex findings" section with one-line justification per item. Commit: `git commit -am "docs(plans): $TASK_SLUG — codex round 1 patches"`.

### 8. Execute the plan — /go stays the Orchestrator

Use `superpowers:executing-plans` as playbook and `superpowers:subagent-driven-development` as execution model. `/go` keeps control of the harness per the `harness-protocol` skill. Sprints run sequentially. Intra-sprint triad is strictly sequential:

1. **Developer** sub-agent: tests first (`superpowers:test-driven-development`), then code. Returns the structured Developer report.
2. **Verifier** sub-agent (fresh, zero context from Developer): reads the diff cold, runs the discovered verification gate + unit + typecheck + E2E-when-mandatory. Returns Verifier report.
3. **Auditor** sub-agent (fresh, e.g., `feature-dev:code-reviewer`): scores each acceptance criterion 0-10 against the plan. Returns Auditor report.

Parallelism rules inside phase 8:
- Across sprints → serial.
- Within a single sprint → roles serial, never parallel.
- Within a single role, truly independent subtasks → fan out via `superpowers:dispatching-parallel-agents`.

If any Auditor score <9 → loop the sprint with Developer, passing failing criteria + evidence. Same sub-agent that failed does NOT also re-evaluate. After Auditor green → commit the sprint.

### 9. Simplify pass

Run `Skill` → `simplify` over `git diff "origin/$DEFAULT_BRANCH"...HEAD`. Accept the suggestions, commit as `refactor($TASK_SLUG): simplify`.

### 10. Verify tree is clean + shipping gate

```bash
git status --porcelain           # must be empty
<discovered verification gate>   # must be green
```

If either fails, loop back to the failing sprint. Do not proceed.

### 11. Final Codex audit — same thread, three labeled buckets — **skip if `CODEX_OK=no`**

Run this call with the same background + 90s-silence watchdog described in phase 6. Do not invoke it in the foreground Bash path.

```bash
SID=$(cat .context/codex-session-id)
codex exec resume "$SID" \
  "Final critical review. The plan you reviewed has now been implemented on \
branch $TASK_SLUG. Review the full diff vs origin/$DEFAULT_BRANCH. \
IMPORTANT: Do NOT read files under ~/.claude/, ~/.agents/, .claude/skills/, \
or agents/. Produce findings in THREE labeled buckets: \
(A) E2E & TEST COVERAGE GAPS — enumerate every user-facing path that \
changed in this diff and whether there is a test covering it. Flag any \
missing coverage for paths the project marks as test-mandatory. Also flag \
unit tests that lack negative/error cases. \
(B) EDGE CASES — list concrete edge cases the implementation does not \
handle: empty states, race conditions, duplicate webhooks, money \
reservation without finalization, provider timeouts, unicode/locale, \
concurrency on shared rows, auth boundary bypasses. Name the file:line \
where each is missing. \
(C) OVER-ENGINEERING — call out speculative abstractions, unused \
parameters, premature generics, dead branches, feature flags with one \
branch, helpers with one caller, and any code whose removal would not \
change behavior. \
Also cover: correctness bugs, security issues, money/state cleanup, \
provider correlation, SSOT violations, stubs masquerading as real wiring. \
Be adversarial." \
  -C "$(pwd)" -s read-only -c 'model_reasoning_effort="high"' \
  --enable web_search_cached --json 2>/dev/null \
| tee .context/codex-final-review.jsonl \
| python3 -c "import sys,json
for line in sys.stdin:
  try: o=json.loads(line)
  except: continue
  t=o.get('type','')
  if t in ('item.completed','agent_message'):
    m=o.get('item',{}).get('text') or o.get('message','')
    if m: print(m)
"
```

### 12. Validate + fix real findings (parallel validation, serial fixes) — **skip if `CODEX_OK=no`**

1. Fan out validation with `superpowers:dispatching-parallel-agents` — one sub-agent per finding, returning `{valid, evidence: file:line, fix_approach}`.
2. **Fixes are serial** (clean commit history, avoid merge conflicts). For each valid finding /go runs the mini-harness: Developer writes failing test first + fix, Verifier runs gates, Auditor confirms resolution. Commit per finding: `fix($TASK_SLUG): <finding>`.
3. Invalid findings → "Rejected final-audit findings" section in the plan with one-line reasoning.
4. If any code changed, re-run the discovered verification gate before declaring done.

### 13. Promote open findings to monthly ledger

If the project has a directory at `docs/retro/codex-findings/`, append
every entry from the plan file's "Rejected final-audit findings" section
whose status is `open` or `deferred` to
`docs/retro/codex-findings/<YYYY-MM>.md` under the `## open` heading.

This is the across-runs memory; without this step the ledger stays
empty and `context-continuity.md`-style "check open findings before
declaring done" rules become no-ops (the gap that triggered phoneapp's
2026-04-26 retro Finding 1).

```bash
LEDGER_DIR=docs/retro/codex-findings
if [ -d "$LEDGER_DIR" ]; then
  MONTH=$(date +%Y-%m)
  LEDGER="$LEDGER_DIR/$MONTH.md"
  # Create the file if missing, with the schema-compliant header.
  if [ ! -f "$LEDGER" ]; then
    cat > "$LEDGER" << EOF
# Codex findings — $MONTH

## open

## closed (current month)
EOF
  fi
  # Extract entries from the plan's Rejected final-audit findings section
  # whose status remains open or deferred, and append to the ledger's
  # "## open" section. Each entry must include caught_by: and provenance:.
  # Implementation: read the plan section programmatically, format per
  # docs/retro/README.md schema, then commit.
  git add "$LEDGER"
  git commit -m "docs(retro): promote $TASK_SLUG open findings to ledger"
fi
```

Each promoted entry must include:
- `[status]` — `blocker` / `major` / `minor`
- `finding-id` — short kebab-case slug
- File path
- `opened YYYY-MM-DD on plan/<plan-file>`
- `caught_by:` — `codex` (default for /go's Codex passes), or
  `auditor` / `devil-advocate` / `second-pass` if the plan file
  attributes differently
- `provenance: extracted` (the entry was lifted from a structured
  Rejected-findings section)

If no `docs/retro/codex-findings/` directory exists in the project,
skip this phase (it's a phoneapp-style ledger convention; not every
project has one).

### 14. Done

Print a concise summary:
- worktree path + branch name
- plan path
- sprint count with pass/fail per sprint
- Codex findings accepted/rejected in both rounds
- count of findings promoted to the monthly ledger (phase 13)
- final verification-gate status
- next step for the user (e.g., `/ship` or open a PR from inside the worktree)

**Do not push or open a PR yourself.** The user owns the merge decision.

## Stop conditions (ask the user; don't guess)

- Task description is unclear or too broad → ask ONE clarifying question, then resume.
- Project discovery yielded no verification gate → ask the user for the command.
- Sprint loop fails 3× on the same acceptance criterion → stop and surface the root cause.
- Verification gate fails with a pre-existing (non-yours) breakage → stop and surface it; do not silently fix unrelated code.
- Codex returns >10 findings in either round → summarize and ask which to prioritize before mass-patching.

## Failure mode notes

- If `codex exec resume` fails (session expired), start a fresh Codex call but re-feed the plan path and the diff summary so it has equivalent context.
- If the worktree already exists, reuse it only if the branch name matches exactly AND `git status` is clean; otherwise pick a numbered suffix (`$TASK_SLUG-2`).
- If the project's toolchain isn't installed in the worktree, bootstrap it once (`pnpm install --frozen-lockfile`, `uv sync`, `cargo fetch`, `go mod download`) before the first Developer spawn.
