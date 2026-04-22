---
name: harness-protocol
description: >
  Use when coordinating a sprinted implementation across sub-agents and you
  need quality gates that can't be talked out of — task spans multiple
  sprints, waves, or >5 files. Trigger phrases: "run the harness", "use
  the protocol", "quality-gated build", "sprinted implementation", "hard
  quality gate". Project-agnostic.
---

# Harness-Orchestrated Development

**Use this for any task spanning multiple sprints, waves, or >5 files.**

The **Orchestrator → Generator → Evaluator** pattern. The main conversation is the orchestrator — it NEVER implements features or evaluates its own work.

```
┌─────────────────────────────────────────────┐
│           ORCHESTRATOR (main session)        │
│                                              │
│  Owns: task list, sprint state, go/no-go     │
│  Never: implements features or evaluates     │
│         its own work                         │
│                                              │
│  Per sprint:                                 │
│    1. Create tasks with acceptance criteria │
│    2. Spawn DEVELOPER agent → implement    │
│    3. Run automated gates (test/type/build)│
│    4. Spawn VERIFIER agent → check work    │
│    5. If FAIL → send fixes to developer    │
│    6. Loop 4-5 until PASS                  │
│    7. Spawn AUDITOR agent → grade >9/10    │
│    8. If <9/10 → fix, re-audit             │
│    9. Only then → next sprint              │
└─────────────────────────────────────────────┘
         │              │              │
    ┌────▼────┐   ┌─────▼─────┐  ┌────▼────┐
    │DEVELOPER│   │ VERIFIER  │  │ AUDITOR │
    │(writes) │   │(checks)   │  │(grades) │
    │Code,    │   │Tests,     │  │Skeptical│
    │E2E tests│   │evidence   │  │>9/10 bar│
    │Fixes    │   │PASS/FAIL  │  │file:line│
    └─────────┘   └───────────┘  └─────────┘
```

## Agent Roles

| Role | What it does | What it NEVER does |
|------|-------------|-------------------|
| **Orchestrator** (main) | Creates tasks, spawns agents, reads reports, decides go/no-go | Implements features, evaluates its own decisions |
| **Developer** (generator) | Implements features, writes tests (unit + E2E where applicable), fixes bugs | Evaluates its own work quality |
| **Verifier** (evaluator #1) | Runs tests, verifies files exist with correct content, reports PASS/FAIL with evidence | Fixes code, softens findings |
| **Auditor** (evaluator #2) | Grades each acceptance criterion 1-10 with file:line evidence, finds problems | Fixes code, praises work, talks itself out of findings |

## Key Rules

1. **Generator never evaluates itself.** Developer doesn't grade its own code.
2. **Evaluator is skeptical by default.** Auditor prompt: *"Find problems, not praise. If unsure, treat it as a bug. Never talk yourself out of a finding."*
3. **Hard threshold: >9/10 per criterion.** Not 7. Not "close enough."
4. **Loops are expected.** 2-3 iterations per sprint is normal and healthy.
5. **Orchestrator reads every report.** No blind trust — verify the evaluator actually ran the checks.
6. **Sub-agents are fresh.** Each evaluator sub-agent starts with zero context from the developer.
7. **Intra-sprint parallelism is forbidden.** Developer → Verifier → Auditor is strictly sequential inside one sprint. Independent subtasks *within* a single role may fan out.

## Per-Sprint Execution Sequence

### Phase A — Implementation
1. Orchestrator creates sprint tasks with acceptance criteria
2. Spawn **Developer agent** with full context (files, plan section, patterns)
3. Developer implements, writes tests, runs the project's automated gates (see below)

### Phase B — Verification
4. Spawn **Verifier agent** (fresh context, no knowledge of developer's intent)
5. Verifier checks: files exist with correct content, tests map to acceptance criteria, gates green

### Phase C — Fix loop
6. Orchestrator forwards FAIL findings to Developer → Developer fixes → Verifier re-checks
7. Loop until all PASS

### Phase D — Audit
8. Spawn **Auditor agent** (completely fresh, skeptical prompt — e.g., `feature-dev:code-reviewer` or `superpowers:code-reviewer`)
9. Auditor grades each criterion 1-10 with file:line evidence
10. If any criterion <9/10 → Developer fixes → Auditor re-grades → loop

### Phase E — Sign-off
11. All gates green, all audit scores >9/10
12. Commit the sprint, proceed to next sprint

### Phase F — Optional final review
13. Consider a final external reviewer (e.g., `/codex review`) on the cumulative diff after all sprints. External reviewers need committed changes and the plan in-repo.

## Automated Gates — project-agnostic discovery

Before any evaluator runs, all of the project's automated gates MUST pass. Detect the project's gate script, in this order:

1. **`.claude/rules/testing-gates.md`** — if present, follow it verbatim (project-specific paths, commands, E2E-mandatory list).
2. **`package.json` scripts** — look for `verify`, `verify:wave`, `ci`, `check`, `test:all`, `precommit`. Use the most comprehensive one.
3. **`Makefile`** targets — `make verify`, `make ci`, `make check`, `make test`.
4. **Language defaults** — fall back to: `pnpm test && pnpm run typecheck && pnpm build` (Node), `uv run pytest && uv run mypy` (Python), `cargo test && cargo clippy` (Rust), `go test ./... && go vet ./...` (Go).

If none resolve, stop and ask the user for the verification command. **Do not invent one.**

## E2E coverage

If the project has a `.claude/rules/testing-gates.md` listing E2E-mandatory paths, diff-changed files that intersect that list trigger a mandatory E2E run before audit. Otherwise require E2E for any user-facing route or money/state transition the sprint touched.

## Independent Auditor Principles

The auditor (spawned fresh, ideally as `feature-dev:code-reviewer` or an equivalent reviewer agent) must be **skeptical by default**:

1. **Self-evaluation is unreliable.** Never let the generator evaluate its own output.
2. **Skepticism must be explicitly prompted.** Auditor prompt: *"You are a skeptical reviewer. Your job is to find problems, not praise. If unsure whether something is a bug, treat it as a bug. Never talk yourself out of a finding."*
3. **Test deeply, not superficially.** Probe edge cases, don't just check happy paths.
4. **Grade against concrete criteria.** Each sprint has acceptance criteria. Grade against THOSE with file:line references. Not vibes.
5. **Hard thresholds, not soft suggestions.** If ANY criterion is below threshold, the sprint FAILS. No exceptions.
6. **Challenge adversarially.** Try to break things: invalid inputs, race conditions, missing wiring, stub features.
7. **Separation is the mechanism.** A standalone evaluator being skeptical is far more tractable than making a generator critical of its own work.
8. **Calibrate through iteration.** If the auditor is too lenient, tighten the prompt next time.

## Sprint Execution (when paired with `/writing-plans` + `/executing-plans`)

Every task follows:
1. **Plan** — define scope, dependencies, acceptance criteria
2. **Implement** — types first, then code (Developer agent)
3. **Verify** — Verifier agent checks implementation independently
4. **Audit** — Auditor agent grades against criteria (>9/10 required)
5. **Fix loop** — iterate until all checks pass
6. **Proceed** — only move to next sprint when harness signs off

**Do NOT batch sprints.** Complete the full harness loop for each before starting the next.

## Return contract between Orchestrator and sub-agents

Each sub-agent returns a structured report so the Orchestrator can make decisions without re-reading raw tool output:

**Developer:** `{ files_changed, tests_added, gates_run, gates_status, diff_summary, notes }`

**Verifier:** `{ gates_status, coverage_map: [{criterion, test_file:line}], failures: [{file:line, reason}], verdict: PASS|FAIL }`

**Auditor:** `{ scores: [{criterion, score_0_10, evidence: file:line, reasoning}], overall_verdict: PASS|FAIL, blocking_findings: [...] }`

Store each report under `.context/harness/<sprint>/<role>.json` for later audit-of-audit and retros.
