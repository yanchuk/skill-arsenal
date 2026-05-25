---
name: harness-protocol
description: >
  Use when coordinating a sprinted implementation across subagents or worker
  models and you need quality gates that can't be talked out of — task spans
  multiple sprints, waves, or >5 files. Supports Claude/Superpowers and Codex
  subagent adapters. Trigger phrases: "run the harness", "use the protocol",
  "quality-gated build", "sprinted implementation", "hard quality gate".
  Project-agnostic.
---

# Harness-Orchestrated Development

**Use this for any task spanning multiple sprints, waves, or >5 files.**

## Runtime adapters

This protocol is runtime-neutral. Claude Code, Codex, OpenCode, and other
agent harnesses are adapters that provide the same roles: Orchestrator,
Developer, Verifier, and Auditor.

Use the strongest available parent model for orchestration and judgment. Use
smaller worker models only when `agent-task-briefs` says the task is bounded,
invariant-first, and mechanically verifiable.

### Claude Code / Superpowers adapter

When [`obra/superpowers`](https://github.com/obra/superpowers) is installed,
invoke these skills by name if they resolve:

- `superpowers:writing-plans`
- `superpowers:subagent-driven-development` (Developer + Verifier briefs read from its `implementer-prompt.md` / `spec-reviewer-prompt.md` references)
- `superpowers:dispatching-parallel-agents`
- `superpowers:test-driven-development`
- `superpowers:requesting-code-review` (used by the Auditor)
- `superpowers:verification-before-completion`

If a caller explicitly selected the Superpowers adapter and these are missing,
stop with a one-line install hint. Do not silently pretend the adapter exists.

### Codex adapter

Codex supports built-in subagents (`default`, `worker`, `explorer`) and custom
agents in `~/.codex/agents/` or `.codex/agents/`. Use Codex agents like this:

- **Orchestrator:** parent Codex session, strongest available model.
- **Developer:** `worker` or a custom implementation agent. A small model such
  as `gpt-5.3-codex-spark` is appropriate only for bounded tasks with explicit
  files, tests, and invariants.
- **Verifier:** read-only custom agent when possible; PASS/FAIL only.
- **Auditor:** reviewer custom agent, preferably read-only and stronger than
  the Developer when correctness, security, or migrations are involved.
- **Scout:** `explorer` or a read-only custom agent for mapping and evidence.

Custom Codex agents can set `model`, `model_reasoning_effort`, `sandbox_mode`,
MCP servers, and skill config. Keep nested delegation shallow; recursive fan-out
adds cost and makes results harder to reason about.

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
1. Orchestrator creates sprint tasks with acceptance criteria. **When the implementer is a junior agent (a worker model or junior agent), shape every task per the `agent-task-briefs` skill** — invariant-first ("What Must Be True"), known constraints with trigger citations from that skill's § 3, and mechanical verification. Implied taste does not survive the handoff.
2. Spawn **Developer agent** with full context (files, plan section, patterns). For boundary-touching work (server routes, schemas, external provider calls, analytics, file uploads, auth), the Developer's prompt MUST include explicit absolute paths to read `agent-task-briefs/SKILL.md` — sub-agents do NOT auto-inherit project rules.
3. Developer implements, writes tests, runs the project's automated gates (see below).

### Phase B — Verification
4. Spawn **Verifier agent** (fresh context, no knowledge of developer's intent)
5. Verifier checks: files exist with correct content, tests map to acceptance criteria, gates green

### Phase C — Fix loop
6. Orchestrator forwards FAIL findings to Developer → Developer fixes → Verifier re-checks
7. Loop until all PASS

### Phase D — Audit
8. Spawn **Auditor agent** (completely fresh, skeptical prompt — e.g., a Codex reviewer custom agent, `feature-dev:code-reviewer`, or `superpowers:requesting-code-review`).
9. Auditor grades each criterion 1-10 with file:line evidence.
10. **For boundary-touching diffs**, the Auditor MUST also enumerate `triggers_satisfied: [{trigger_id, file, line}]` for every trigger in `agent-task-briefs/SKILL.md` § 3 that applies to the diff. Empty enumeration on a boundary diff is an audit failure — either the auditor didn't check or the implementer didn't apply.
11. If any criterion <9/10 → Developer fixes → Auditor re-grades → loop.

### Phase E — Sign-off
11. All gates green, all audit scores >9/10
12. Commit the sprint, proceed to next sprint

### Phase F — Optional final review
13. Consider a final external reviewer (e.g., `/codex review`) on the cumulative diff after all sprints. External reviewers need committed changes and the plan in-repo.

## Automated Gates — project-agnostic discovery

Before any evaluator runs, all of the project's automated gates MUST pass. Detect the project's gate script, in this order:

1. **Runtime testing gate rules** — if `.claude/rules/testing-gates.md`, `.codex/rules/testing-gates.md`, or an equivalent runtime rule exists, follow it verbatim (project-specific paths, commands, E2E-mandatory list).
2. **`package.json` scripts** — look for `verify`, `verify:wave`, `ci`, `check`, `test:all`, `precommit`. Use the most comprehensive one.
3. **`Makefile`** targets — `make verify`, `make ci`, `make check`, `make test`.
4. **Language defaults** — fall back to: `pnpm test && pnpm run typecheck && pnpm build` (Node), `uv run pytest && uv run mypy` (Python), `cargo test && cargo clippy` (Rust), `go test ./... && go vet ./...` (Go).

If none resolve, stop and ask the user for the verification command. **Do not invent one.**

## E2E coverage

If the project has `.claude/rules/testing-gates.md`, `.codex/rules/testing-gates.md`, or an equivalent runtime rule listing E2E-mandatory paths, diff-changed files that intersect that list trigger a mandatory E2E run before audit. Otherwise require E2E for any user-facing route or money/state transition the sprint touched.

## Independent Auditor Principles

The auditor (spawned fresh, ideally as a dedicated reviewer custom agent, `feature-dev:code-reviewer`, or an equivalent review skill) must be **skeptical by default**:

1. **Self-evaluation is unreliable.** Never let the generator evaluate its own output.
2. **Skepticism must be explicitly prompted.** Auditor prompt: *"You are a skeptical reviewer. Your job is to find problems, not praise. If unsure whether something is a bug, treat it as a bug. Never talk yourself out of a finding."*
3. **Test deeply, not superficially.** Probe edge cases, don't just check happy paths.
4. **Grade against concrete criteria.** Each sprint has acceptance criteria. Grade against THOSE with file:line references. Not vibes.
5. **Hard thresholds, not soft suggestions.** If ANY criterion is below threshold, the sprint FAILS. No exceptions.
6. **Challenge adversarially.** Try to break things: invalid inputs, race conditions, missing wiring, stub features.
7. **Separation is the mechanism.** A standalone evaluator being skeptical is far more tractable than making a generator critical of its own work.
8. **Calibrate through iteration.** If the auditor is too lenient, tighten the prompt next time.

## Sprint Execution (when paired with a plan runner)

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

**Verifier:** `{ gates_status, coverage_map: [{criterion_id, test_file:line}], failures: [{file:line, reason}], verdict: PASS|FAIL }`
- `criterion_id` is the `Vn` ID from the Validation Contract (see below). Verifier MUST map every `Vn` claimed by the sprint to a `test_file:line`. Any claimed `Vn` without a covering test → `verdict: FAIL`.

**Auditor:** `{ scores: [{criterion_id, criterion_text, score_0_10, evidence: file:line, reasoning}], unclaimed_assertions: [Vn...], overall_verdict: PASS|FAIL, blocking_findings: [...] }`
- `criterion_id` is the `Vn` ID being scored.
- `unclaimed_assertions` lists any `Vn` from the plan's Validation Contract that is not claimed by any task. Non-empty → `overall_verdict: FAIL`.
- Auditor verdict rule: any claimed `Vn` with `score_0_10 < 9` OR non-empty `unclaimed_assertions` OR any `severity: blocker` finding → `FAIL`.
- **Auditor brief:** see `references/auditor-prompt.md`. The orchestrator composes the brief by reading that file plus filling in `PINNED_COMMIT`, `PLAN_PATH`, `SPRINT`, `SPRINT_DIFF_RANGE`, `TASK_VALIDATES`, `VALIDATION_CONTRACT`. Do NOT inline the prompt at dispatch sites — reference the file so updates propagate.

Store each report under `.context/harness/<sprint>/<role>.json` for later audit-of-audit and retros.

## Validation Contract

The Auditor scores against a **flat, numbered list of typed assertions** (`V1`, `V2`, …) authored *before* any code, not against scattered acceptance-criteria text. The orchestrator (e.g., `/go` Phase 2.6) is responsible for producing this list and embedding it in the plan; this skill defines the rules every `Vn` MUST satisfy.

### Assertion shape

Every `Vn` MUST be expressible as one of:

- **(a) HTTP** — `Vn: <METHOD> <path> [while <precondition>] → <status>, body contains "<string>"`
  Example: `V3: POST /payments {amount: -1} → 400, body contains "amount must be positive"`.

- **(b) DB / state** — a row-level state assertion expressible as a query.
  Example: `V7: after V3, payments table row count unchanged`.

- **(c) UI** — a user-visible string at a CSS / role selector.
  Example: `V12: at /dashboard while unauthenticated, [role=heading] reads "Sign in to continue"`.

### Forbidden assertion shapes (rejected at `plan-review`)

- **Pure intent restatements.** "V3: payments page exists." If a human can't observe failure from outside the system, the assertion is wrong.
- **Internal-state-only assertions.** "V8: cache key is set." Internal state is not a user-observable contract.
- **Compound assertions.** One `Vn` per behavior; split if joined by AND/OR.

### Coverage rules

- **Cap:** ≤15 `Vn` per task ≤3 sprints. >15 → scope alarm; `plan-review` flags it.
- **Every task** in the plan MUST declare `validates: [Vn, ...]` (≥1 entry). Tasks with empty `validates:` fail `plan-review`.
- **Every `Vn`** MUST be claimed by ≥1 task. Unclaimed `Vn` fails `plan-review`.

### Where it lives in the plan

The orchestrator inserts a `## Validation Contract` section in the plan file with the full numbered list, and annotates each task header with an inline marker:

```markdown
### Task 3: idle session timeout
<!-- validates: [V3, V7] -->
```

The harness reads `validates:` markers per task at sprint dispatch time; the Auditor brief receives both the per-sprint claims and the full Validation Contract verbatim.
