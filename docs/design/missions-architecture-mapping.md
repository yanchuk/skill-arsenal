# Missions architecture → skill-arsenal mapping

**Status:** design doc (Path B locked, 2026-05-10)
**Owner:** harness-protocol + /go
**Companion PR:** adds Validation Contract + hard `obra/superpowers` dependency

## Context

Source material: Luke Alvoeiro's *"The Multi-Agent Architecture That Actually Ships"* (Factory). The talk describes **Missions** — a multi-day, multi-agent system combining four communication patterns (delegation, creator-verifier, broadcast, negotiation) under a three-role architecture (orchestrator, workers, validators).

We compared Missions against our existing `/go` and `/harness-protocol` skills, ranked the gaps, and ran a devil-advocate review. Result: only one idea earned its keep this round — a **Validation Contract** of typed `Vn` assertions written *before* code, against which the Auditor scores. Everything else is deferred behind a measurement gate.

This doc is the canonical record of what we shipped, what we deferred, and the success criterion that decides whether the deferred phases get built.

## Visual: dependency graph (after this PR)

```
                       ┌─────────────────────────────┐
                       │   skill-arsenal (this repo) │
                       └─────────────────────────────┘
                                      │
                ┌─────────────────────┴─────────────────────┐
                ▼                                           ▼
       ┌────────────────┐                          ┌─────────────────┐
       │     /go        │  ─── invokes ──▶         │ harness-protocol│
       │ (orchestrator) │                          │ (Dev/Verify/Audit)
       └───────┬────────┘                          └────────┬────────┘
               │                                            │
               │  HARD DEPENDENCY (Phase 1 fail-fast probe) │
               ├────────────────────┬───────────────────────┤
               ▼                    ▼                       ▼
   ┌──────────────────────────────────────────────────────────────────┐
   │                   obra/superpowers (required)                    │
   ├──────────────────────────────────────────────────────────────────┤
   │  superpowers:writing-plans            ◀── /go Phase 2            │
   │  superpowers:subagent-driven-development                          │
   │       └─ implementer-prompt.md         ◀── Developer brief        │
   │       └─ spec-reviewer-prompt.md       ◀── Verifier brief         │
   │       └─ code-quality-reviewer-prompt.md                          │
   │  superpowers:dispatching-parallel-agents ◀── scout fan-out       │
   │  superpowers:test-driven-development                              │
   │  superpowers:requesting-code-review   ◀── Audit invocation        │
   │  superpowers:verification-before-completion                       │
   │  superpowers:finishing-a-development-branch ◀── /go Phase 14      │
   └──────────────────────────────────────────────────────────────────┘
                                      ▲
                                      │ if any missing →
                                      │ /go Phase 1 aborts with
                                      │ install hint, no worktree commit
```

Soft / optional dependencies (unchanged):
- `codex` CLI — second-opinion auditor at Phase 6 + Phase 11. Skipped cleanly when unavailable.
- `agent-task-briefs` (in this arsenal) — worker-agent placement + brief shaping, already wired.
- `plan-review` (in this arsenal) — plan critique at Phase 4.
- `simplify` — code-deduplication pass at Phase 9.

---

## Visual: how a `/go` run flows now (Validation Contract path)

```
USER: /go add idle-session timeout to /dashboard
   │
   ▼
┌──────────────────────────────────────────────────────────────────────┐
│  Phase 1   Setup worktree + project discovery                        │
│            + SUPERPOWERS PROBE  ────▶  any missing? abort            │
│            + Codex readiness probe                                   │
└──────────────────────────────────────────────────────────────────────┘
   │
   ▼
┌──────────────────────────────────────────────────────────────────────┐
│  Phase 2   superpowers:writing-plans  →  detailed engineering plan   │
└──────────────────────────────────────────────────────────────────────┘
   │
   ▼
┌──────────────────────────────────────────────────────────────────────┐
│  Phase 2.5 Worker-agent eligibility tagging (per task)                     │
└──────────────────────────────────────────────────────────────────────┘
   │
   ▼
┌────────────────────────────── NEW ───────────────────────────────────┐
│  Phase 2.6 Author Validation Contract                                │
│            Extract typed Vn assertions from plan:                    │
│              V1: HTTP   GET /dashboard while logged-out → 302 /login │
│              V2: UI     [role=alert] reads "Session expired"         │
│              V3: STATE  sessions row deleted after 15min idle        │
│            Annotate every task with  validates: [V1, V2, ...]        │
│            Append "Worker-agent eligibility table" + "Validation Contract" │
└──────────────────────────────────────────────────────────────────────┘
   │
   ▼
┌──────────────────────────────────────────────────────────────────────┐
│  Phase 3   Append Harness Protocol section (sprints + ≥9/10 gate)    │
└──────────────────────────────────────────────────────────────────────┘
   │
   ▼
┌──────────────────────────────────────────────────────────────────────┐
│  Phase 4   plan-review                                               │
│            ├─ checks Vn shape: HTTP / DB-state / UI selector only    │
│            ├─ flags pure-intent Vn ("V3: page exists")  ▶ REJECT     │
│            ├─ checks every task has  validates: [≥1]                 │
│            └─ checks every Vn claimed by ≥1 task                     │
└──────────────────────────────────────────────────────────────────────┘
   │
   ▼
   Phase 5–7  (unchanged: commit plan, optional Codex review)
   │
   ▼
┌──────────────────────────────────────────────────────────────────────┐
│  Phase 8   Execute sprints under harness                             │
│                                                                      │
│   per sprint:                                                        │
│   ┌────────────┐    ┌────────────┐    ┌─────────────────────────┐    │
│   │ Developer  │ ▶  │  Verifier  │ ▶  │   Auditor (brain model) │    │
│   │ (impl+test)│    │ (PASS/FAIL │    │ scores against Vn list  │    │
│   │            │    │  evidence) │    │ ┌─────────────────────┐ │    │
│   └────────────┘    └────────────┘    │ │ score(V1) = 9.2     │ │    │
│         ▲                  ▲           │ │ score(V2) = 7.0  ✗  │ │    │
│         │                  │           │ │ unclaimed: [V3]  ✗  │ │    │
│         │                  │           │ └─────────────────────┘ │    │
│         │                  │           │ verdict: FAIL           │    │
│         │                  │           └────────────┬────────────┘    │
│         │                  └─── re-verify ─────────┤                  │
│         └─── fix ◀── failing Vn + evidence ────────┘                  │
│                                                                      │
│  brief composer reads:                                               │
│   • Developer  ← superpowers:subagent-driven-development/             │
│                  implementer-prompt.md  +  validates: [Vn] markers   │
│   • Verifier   ← superpowers:subagent-driven-development/             │
│                  spec-reviewer-prompt.md  +  validates: [Vn] markers │
│   • Auditor    ← harness-protocol/references/auditor-prompt.md       │
│                  +  full Vn table verbatim                           │
└──────────────────────────────────────────────────────────────────────┘
   │
   ▼
   Phase 9–14  (unchanged: simplify, ship gate, Codex final, ledger, done)
```

---

## Visual: what we improved (before / after)

```
                       BEFORE                                AFTER
   ┌──────────────────────────────────────┐   ┌──────────────────────────────────────┐
   │ Plan has acceptance criteria         │   │ Plan has acceptance criteria         │
   │ scattered through task descriptions, │   │ AND a flat Validation Contract:      │
   │ in free-text form like:              │   │   V1: HTTP   GET /x → 200, body...   │
   │   "tests should cover the timeout"   │   │   V2: UI     selector reads "..."    │
   │   "must handle invalid input"        │   │   V3: STATE  row count unchanged     │
   │   "page should render correctly"     │   │ Each task says:  validates: [V1, V3] │
   └────────────────┬─────────────────────┘   └────────────────┬─────────────────────┘
                    │                                          │
                    ▼                                          ▼
   ┌──────────────────────────────────────┐   ┌──────────────────────────────────────┐
   │ Auditor reads task text, decides     │   │ Auditor reads Vn table, scores each  │
   │ "did the impl meet the criterion?"   │   │ Vn against the diff with file:line,  │
   │                                      │   │ flags any Vn not claimed by a task,  │
   │ → judgment-heavy                     │   │ rejects paraphrase Vn outright       │
   │ → bias toward "looks fine"           │   │                                      │
   │ → criteria can drift from intent     │   │ → mechanical, evidence-based         │
   │                                      │   │ → can't grade what isn't enumerated  │
   │ → escapes show up at Phase 11 Codex  │   │ → escapes drop (target: ≥30%)        │
   └──────────────────────────────────────┘   └──────────────────────────────────────┘

   ┌──────────────────────────────────────┐   ┌──────────────────────────────────────┐
   │ Auditor brief inlined ~30 lines of   │   │ Auditor brief = one read of          │
   │ skeptical-prompt at every dispatch   │   │ harness-protocol/references/          │
   │ site → drift between sites           │   │ auditor-prompt.md                    │
   └──────────────────────────────────────┘   └──────────────────────────────────────┘

   ┌──────────────────────────────────────┐   ┌──────────────────────────────────────┐
   │ obra/superpowers was an "if          │   │ obra/superpowers is a HARD dep.      │
   │ available" reference. Could silently │   │ /go Phase 1 probes for all 7 skills, │
   │ degrade if missing.                  │   │ aborts cleanly with install hint     │
   │                                      │   │ if any missing. No silent degrade.   │
   └──────────────────────────────────────┘   └──────────────────────────────────────┘
```

**Net effect:** the Auditor stops being a judgment seat ("does this implementation look right?") and becomes a mechanical scorer ("for each pre-declared Vn, find the test:line that proves it, score 0–10"). What used to be subjective grading becomes enumerable coverage.

---

## What we already match (no changes)

| Missions concept | Existing implementation |
|---|---|
| Three-role split (orchestrator / worker / validator) | `harness-protocol` SKILL.md (Developer / Verifier / Auditor) |
| Skeptical-by-default validator | `harness-protocol` § Independent Auditor Principles |
| Fresh context per role | `harness-protocol` Key Rules #6 |
| Serial features; parallelism only on read-only ops | `harness-protocol` Key Rules #7; `/go` § Non-negotiable guardrails |
| Structured handoff JSON | `harness-protocol` § Return contract |
| Hard pass/fail threshold | `harness-protocol` Key Rules #3 (`>9/10`) |
| Right-model-per-role ("droid whispering") | `/go` § Model tiering |
| Different-provider 2nd opinion validator | `/go` Codex passes (phases 6, 11) |
| Logic in prompts, not state machines | both skills are markdown-only |
| Project-discovered gates | `harness-protocol` § Automated Gates; `/go` § Project discovery |

## What ships in this PR (Path B)

### The Validation Contract

A flat numbered list of typed assertions, authored *before* any code, that the Auditor scores against directly.

**Each `Vn` MUST be one of:**
- **(a) HTTP** — `Vn: <METHOD> <path> → <status>, body contains <string>`
- **(b) DB / state** — `Vn: <one-line state assertion expressible as a query>`
- **(c) UI** — `Vn: at <route> while <precondition>, <selector> reads "<string>"`

**Rejected at `plan-review`:**
- Pure intent restatements ("V3: payments page exists")
- Internal-state-only assertions ("V8: cache key is set")
- Compound assertions (one `Vn` per behavior)

**Caps:**
- ≤15 `Vn` per task ≤3 sprints. Over-cap → scope alarm.
- Every task declares `validates: [Vn...]` (≥1).
- Every `Vn` claimed by ≥1 task.

### Hard `obra/superpowers` dependency

Both `/go` and `/harness-protocol` now declare `obra/superpowers` as a hard dependency. Phase 1 of `/go` probes for the seven required superpowers skills via the `Skill` tool and aborts with an install hint if any are missing. No silent degradation.

### Auditor brief — extracted to a reference file

`plugins/harness-protocol/skills/harness-protocol/references/auditor-prompt.md` holds the skeptical-Auditor prompt with `Vn`-scoring + paraphrase-rejection rules. Brief composer at every Auditor dispatch site reads from this file instead of inlining ~30 lines of prompt.

### Auditor return contract — extended

```jsonc
{
  "scores": [
    { "criterion_id": "Vn", "criterion_text": "...", "score_0_10": 0,
      "evidence": "file:line", "reasoning": "..." }
  ],
  "unclaimed_assertions": ["Vn", "..."],
  "overall_verdict": "PASS|FAIL",
  "blocking_findings": [...]
}
```

Verdict rule: any `Vn` with `score < 9` OR present in `unclaimed_assertions` → FAIL.

## What we deferred (and why)

| ID | Phase | Why deferred |
|---|---|---|
| P2 | Brainstorming wiring | Cheap to add later once we know whether ambiguous briefs are actually a frequent failure mode. |
| P3 | Enriched Developer handoff | Devil-advocate review (V6): `procedure_adherence` overlaps the Auditor's existing job. `commands_run[]` alone may be worth adding next round; revisit after baseline. |
| P4 | Behavioral Validator | Devil-advocate (V1): no current mechanism to boot/seed/teardown a dev server in our skills. Needs design work, not just dispatch. |
| P5 | Broadcast surface | Devil-advocate (V6): plan file already serves as shared state. No named failure mode this would fix. |
| P6 | Mission Backlog | Same. Single-laptop sessions don't run long enough to need cross-mission backlogs. |
| P8 / P9 | Agent discovery + role routing | High value, but depends on declared `role:` frontmatter (V4 fix). Better to ship after we see Validation Contract data. |
| P10 | Role templates (product-manager, tech-lead, behavioral-validator) | Reuse > duplicate. Only revisit if specific gaps surface. |

## Success criterion (the gate that unlocks deferred phases)

Capture a baseline before this PR merges, and a comparable post-merge sample. Each row is one `/go` run inspected from `~/.agent-worktrees/`.

| run-slug | (a) sprints needing >1 audit loop | (b) escapes caught only at Phase 11 Codex | (c) post-merge fixes attributable to missed scope | notes |
|---|---|---|---|---|
| _baseline-1_ | TBD | TBD | TBD | |
| _baseline-2_ | TBD | TBD | TBD | |
| _baseline-3_ | TBD | TBD | TBD | |
| _baseline-4_ | TBD | TBD | TBD | |
| _baseline-5_ | TBD | TBD | TBD | |
| **baseline avg** | TBD | TBD | TBD | |
| _post-merge-1_ | TBD | TBD | TBD | |
| _post-merge-2_ | TBD | TBD | TBD | |
| _post-merge-3_ | TBD | TBD | TBD | |
| _post-merge-4_ | TBD | TBD | TBD | |
| _post-merge-5_ | TBD | TBD | TBD | |
| **post-merge avg** | TBD | TBD | TBD | |

**Stage 1 success:** post-merge **(b) drops ≥30%** vs. baseline. If yes, schedule P3-light + P9 next. If no, the Validation Contract shape needs revisiting — do not pile on more phases.

## Devil-advocate findings — disposition

| ID | Finding | Disposition |
|---|---|---|
| V1 | P4 lacks dev-server lifecycle | Deferred — P4 not in this PR. |
| V2 | `Vn` could become paraphrase | **Folded into spec** (typed-assertion rules above). |
| V3 | P10 provisioning has versioning + branch issues | Deferred — P10 not in this PR. |
| V4 | Discovery via keyword matching is brittle | Deferred — P8/P9 not in this PR. When built, will use declared `role:` frontmatter. |
| V5 | Hardcoded superpowers paths are fragile | **Folded** — references resolve via skill name (`superpowers:<name>`), not path. |
| V6 | Scope creep | **Cut to one item.** |
| V7 | Opt-in flag stays off forever | Moot — P4 not in this PR. |
| V8 | Lockstep version coupling | **Folded** — only the skills whose SKILL.md changed get bumped this PR. |
| V9 | No baseline metric | **Folded** — see § Success criterion. |

## File-touch summary (this PR)

- `plugins/harness-protocol/skills/harness-protocol/references/auditor-prompt.md` — new
- `plugins/harness-protocol/skills/harness-protocol/SKILL.md` — Required deps, Validation Contract, Auditor return-contract extension
- `plugins/harness-protocol/.claude-plugin/plugin.json` — minor bump
- `plugins/go/skills/go/SKILL.md` — Required deps, Phase 2.6, 16-item todo list, Phase 4 + Phase 8 brief updates
- `plugins/go/.claude-plugin/plugin.json` — minor bump
- `.claude-plugin/marketplace.json` — both versions in lockstep
- `docs/design/missions-architecture-mapping.md` — this file
- `docs/skill-relations.md` — add hard-dep edges to `superpowers:*`
