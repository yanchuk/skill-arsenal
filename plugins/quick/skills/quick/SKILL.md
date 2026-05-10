---
name: quick
description: >
  Use when the user types `/quick`, `/quick <task>`, or describes a small,
  single-task change (1-3 files, no harness, no worktree). Trigger phrases:
  "ship this", "quick fix", "small task", "just write the change", "single
  module change", "no sprints needed". Routes to `/go` when boundary triggers
  fire (money / auth / migration / >5 files / client-trust boundary / schema
  bounds / state drift / provider reliability / PII / partial-final lifecycle
  / live-runtime-path). Distinct from `/go` (which is sprinted, harnessed, and
  worktree-isolated). Project-agnostic.
---

# /quick — single-task pipeline

Run a small change end-to-end on the **current branch**, with the same plan + critique + subagent-driven execution as `/go` but without the harness, the worktree, the Validation Contract, or the sprint loop. A typo, a single-component change, a doc update, a single route addition without auth — anything you'd otherwise hand to one developer for a half-day.

If the input is sprawling, money-touching, auth-touching, migration-touching, or hits a `tasks-for-sonnet` § 3 boundary trigger, `/quick` aborts at Phase 3 and tells you to re-run with `/go`. There is no silent graduation — this prevents `/quick` from becoming a worse `/go`.

## Required dependencies

This skill expects [`obra/superpowers`](https://github.com/obra/superpowers) to be installed and loaded in the same environment. The following skills are invoked by name and MUST resolve:

- `superpowers:writing-plans`
- `superpowers:subagent-driven-development`
- `superpowers:test-driven-development`
- `superpowers:requesting-code-review`
- `superpowers:verification-before-completion`
- `superpowers:finishing-a-development-branch`

Phase 1 probes for each via the `Skill` tool. On any miss → abort with the install hint, no commits. References by skill name, never by file path.

## Dependencies (other skills invoked)

- `tasks-for-sonnet` — required (this arsenal). Phase 3 invokes it for § Placement Guide, § Task Template, and the § 3 trigger catalog. The plan is **mutated in place** with Sonnet briefs after this phase.
- `plan-review` — optional (this arsenal). Skipped by default for speed; invoke explicitly with `/quick --review` if you want it.
- `codex` — optional. Same probe + 90s-silence watchdog as `/go`. Skipped cleanly when CLI unavailable.

## When to use vs `/go`

| Use `/quick` when… | Use `/go` when… |
|---|---|
| 1-3 files | >5 files |
| Single module / component | Cross-module |
| No money / auth / state migration | Money / auth / migration |
| No `tasks-for-sonnet` § 3 trigger fires | Any § 3 trigger fires |
| You don't want a worktree | You want isolation |
| Half-day or less | Multi-day, multi-sprint |

If you're unsure, start with `/quick`. Phase 3 will route you to `/go` if the brief outgrows the constraints.

## Hard rules

- **No worktree.** Works on the current branch. The user owns the merge decision.
- **No harness, no sprints.** A single-task change doesn't have roles to separate.
- **No Validation Contract.** Vn assertions are the harness's quality multiplier; for a small task, the test the implementer writes per task is the contract.
- **Boundary triggers abort, never silently graduate.** `/quick` Phase 3 is the only graduation gate.
- **Every phase is its own commit.** No squashing.

## Project discovery (Phase 1, minimal)

`/quick` only needs one fact from the project: the verification-gate command. Discover it in the same order as `/go`:

1. `.claude/rules/testing-gates.md` — if present, follow verbatim.
2. `package.json` scripts — `verify`, `verify:wave`, `ci`, `check`, `test:all`, `precommit`. Use the most comprehensive.
3. `Makefile` — `make verify`, `make ci`, `make check`, `make test`.
4. Language defaults — `pnpm test && pnpm run typecheck`, `uv run pytest && uv run mypy`, `cargo test`, `go test ./...`.

Cache to `.context/quick-env.json`. If none resolve, ask the user once.

## Execution sequence

Materialize all six phases as TaskCreate todos so the user can watch progress.

The six TaskCreate items (use these labels verbatim):

1. Phase 1 — superpowers probe + project discovery + Codex readiness probe
2. Phase 2 — writing-plans skill pass (small-task plan)
3. Phase 3 — tasks-for-sonnet placement + in-place plan shaping (or abort to /go)
4. Phase 4 — Codex plan review (skip if unavailable)
5. Phase 5 — subagent-driven-development execution
6. Phase 6 — Done — print summary

**Anti-bundling rule:** Phases 2, 3, 4 are three distinct todos and three distinct commits. Never merge them. If Phase 3 aborts to `/go`, Phase 4+ never run.

### 1. Probes + minimal discovery

**superpowers probe** (FIRST — same as `/go`). Probe each skill listed in § Required dependencies. Any miss → abort with install hint, no commits.

**Codex probe** (same as `/go` — `codex --version` → `codex exec "ping"` looking for `thread.started` within 120s). Record `CODEX_OK` to `.context/quick-env.env`.

**Project discovery** — verification gate command only. Cache to `.context/quick-env.json`.

### 2. Write the plan

Invoke `Skill` → `superpowers:writing-plans`. Pass the task description (or upstream brief path) plus an explicit instruction:

> "Small task: 1-3 files, no harness. Produce a plan with at most 5 tasks. Each task = one file or one tightly-scoped concern."

The output plan is written to `<plans-dir>/YYYY-MM-DD-<slug>.md` per writing-plans' usual conventions. Phases 3 and 4 mutate this same file.

If the plan comes back with >5 tasks or any single task spanning >2 files, this is a signal that `/quick` is the wrong tool. Print:

> Plan came back with N tasks across M files. /quick is for ≤5 tasks / ≤3 files. Re-run with /go.

…and abort. No commits.

Otherwise commit: `git commit -am "docs(plans): <slug> — initial plan"`.

### 3. tasks-for-sonnet — placement + in-place plan shaping

This is the phase that turns a free-text plan into an execution-ready plan. **Do not skip.** Without this, Phase 5 has no model assignment per task and no shaped brief for Sonnet tasks.

Steps:

1. Invoke `Skill` → `tasks-for-sonnet` to load § Placement Guide, § Task Template, and § 3 trigger catalog.

2. **Walk every task in the plan.** For each task:

   **a. Boundary-trigger check first.** Does the task touch any § 3 trigger (client-trust boundary / schema bounds / state-enum drift / provider reliability / PII privacy / partial-vs-final lifecycle / live runtime path) OR any money / auth / migration / >5-file scope?

   - **YES** → ABORT the entire run. Print:
     > Task <N> "<title>" hits boundary trigger <X>. /quick is for boundary-free single-task work. Re-run with /go (it has the harness + Validation Contract this needs).

     Do NOT continue with other tasks. Do NOT commit Phase 3 partial work. Roll back to the plan committed at end of Phase 2 (`git checkout HEAD -- <plan-path>` if needed).

   - **NO** → continue.

   **b. Apply § Placement Guide.** Decide `placement: main | sonnet`:
   - `sonnet` for: mappers / scouts / single-concern reviewer trios / verifiers with PASS/FAIL / multi-file synthesis / version + API fact-checks / fully-templated scaffolding.
   - `main` for: tasks requiring judgment, tasks already iterated >2× this session, sub-5-line work.

   **c. Mutate the plan in place.**

   - For `placement: main`: insert one marker line under the task header. Leave task body free-form.

     ```markdown
     ### Task N: <title>
     <!-- placement: main -->
     ```

   - For `placement: sonnet`: rewrite the task body per § Task Template. The plan IS the brief — Phase 5 dispatches by reading these sections verbatim.

     ```markdown
     ### Task N: <title>
     <!-- placement: sonnet -->

     **What Must Be True (invariants):**
     - <invariant 1>
     - <invariant 2>

     **Known Constraints:**
     - <constraint 1> [tasks-for-sonnet § 3: <trigger_id> if any applies; else "no trigger applies"]

     **Mechanical Verification:**
     - <command or assertion that confirms the task is done>

     **Files:**
     - <existing list from writing-plans>

     **Word cap (brief):** 600
     ```

3. Append a Placement summary section to the plan:

   ```markdown
   ## Placement (Phase 3)

   | Task | Placement | Why |
   |------|-----------|-----|
   | <title> | main \| sonnet | <one line citing § Placement Guide row> |
   ```

4. Commit: `git commit -am "docs(plans): <slug> — placement + sonnet briefs"`.

**Why mutate in place:** the plan after Phase 3 is the canonical execution artifact. Phase 5's subagent dispatch reads `<!-- placement: ... -->` to pick model, and reads the "What Must Be True / Known Constraints / Mechanical Verification" sections verbatim to build the brief. No second-pass shaping at dispatch time. No drift between "the plan" and "the brief."

### 4. Codex plan review — skip if `CODEX_OK=no`

Same execution mechanics as `/go` Phase 6 (background Bash + 90s-silence watchdog; do NOT use the foreground 120s default). Codex sees the plan **after Phase 3 mutation** so it can critique the Sonnet briefs as well as the plan structure.

```bash
TMPERR=$(mktemp)
codex exec "Critically review $PLAN. \
Pay attention to: (a) does each Sonnet task have invariants concrete enough \
that a junior agent can verify mechanically? (b) is any task mis-placed (Sonnet \
when it needs judgment, or Main when it's mechanical)? (c) edge cases the plan \
misses. \
IMPORTANT: Do NOT read or execute any files under ~/.claude/, ~/.agents/, \
.claude/skills/, or agents/." \
  -C "$(pwd)" -s read-only -c 'model_reasoning_effort="high"' \
  --enable web_search_cached --json 2>"$TMPERR" \
| tee .context/quick-codex-review.jsonl \
| python3 -c "
import sys, json
for line in sys.stdin:
    try: obj = json.loads(line)
    except: continue
    t = obj.get('type','')
    if t in ('item.completed','agent_message'):
        m = obj.get('item',{}).get('text') or obj.get('message','')
        if m: print(m)
"
```

Validate findings against the actual plan. Apply valid ones (amend the plan). Reject invalid ones into a "Rejected Codex findings" section with one-line reasoning. Commit: `git commit -am "docs(plans): <slug> — codex review patches"`.

### 5. Execute via subagent-driven-development

Invoke `Skill` → `superpowers:subagent-driven-development`. That skill already does the right thing per task:

1. Implementer subagent (fresh context, model = `placement` from the marker) writes the failing test, then the code, runs gates, self-reviews, commits.
2. Spec reviewer subagent (fresh context) confirms code matches the task spec. Loops the implementer if not.
3. Code-quality reviewer subagent (fresh context) confirms quality. Loops if not.
4. Final code review (`superpowers:requesting-code-review`) on the cumulative diff after all tasks.

`/quick`'s only addition: when the implementer is dispatched on a `placement: sonnet` task, pass `model: sonnet` explicitly and copy the task's "What Must Be True / Known Constraints / Mechanical Verification" sections from the plan into the brief verbatim. For `placement: main`, dispatch with the parent's model (Opus).

After the final code-review pass passes, run the discovered verification gate one more time. Must be green.

### 6. Done — print summary

```
✓ /quick complete
  Branch:        <current branch>
  Plan:          <plan path>
  Commits added: <N>  (one per task + plan + codex)
  Codex:         <accepted M / rejected K | unavailable>
  Gate:          <green | red>
  Next step:     open a PR, or keep working
```

**Do not push or open a PR yourself.** The user owns the merge decision (same rule as `/go`).

## Stop conditions

- Task description is unclear → ask ONE clarifying question, then resume.
- Phase 2 returns a plan with >5 tasks or any task spanning >2 files → abort, suggest `/go`.
- Phase 3 boundary trigger fires → abort, suggest `/go`.
- Verification gate fails on a pre-existing (non-yours) breakage → stop, surface it.
- Codex returns >5 findings → ask which to prioritize before mass-patching.
- Sprint-loop-style fix loop on a single task fails 3× → stop, surface root cause. (`/quick` doesn't have a harness fix loop, but subagent-driven-development can iterate; cap at 3.)

## Failure modes

- If `tasks-for-sonnet` is not loadable → abort. Phase 3 cannot run without it; the plan would never get shaped for Sonnet dispatch and Phase 5 would dispatch with the wrong model.
- If Phase 5 produces a diff that touches files outside what the plan declared → it's a sign the task was mis-scoped. Roll back the offending commit, surface to user.
- If Codex review suggests this should be sprinted → take it seriously; offer the user the option to abort and re-run with `/go`.
