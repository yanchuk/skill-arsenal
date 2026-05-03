# Changelog

All notable changes to skill-arsenal are tracked here. Format loosely follows
[Keep a Changelog](https://keepachangelog.com/en/1.1.0/) and [SemVer](https://semver.org/).

## [Unreleased]

### Added
- **`tasks-for-sonnet` skill** — Invariant-first task-writing for junior implementation agents (Sonnet / Haiku / any LLM acting as Developer in a harness loop). Converts vague instructions into mechanically verifiable tasks with explicit trigger conditions, TDD steps, and harness handoff. Ships a stack-agnostic trigger catalog promoted from observed external-reviewer catches: client-trust boundary (omit server-owned fields), schema bounds (trim/min/max/int/nonnegative), state drift (single source of truth + DB enum), provider reliability (timeout + shape + non-empty), PII (allowlist + hashed identifiers), partial-vs-final lifecycle (paired refinement on terminal boundary). Defines a Skill Update Loop so future reviewer catches feed back into the trigger catalog instead of being one-off ledger entries. Standalone — pairs with `harness-protocol` (consumes the tasks) and `retrospective` (promotes new triggers).
- **`harness-protocol` skill** — Orchestrator → Developer → Verifier → Auditor pattern for multi-sprint work. Project-agnostic; discovers the project's verification gate from `.claude/rules/testing-gates.md`, `package.json` scripts, or `Makefile`. Hard >9/10 per-criterion threshold. Generator never self-evaluates; intra-sprint triad is strictly sequential; within a single role, independent subtasks may fan out via `superpowers:dispatching-parallel-agents`. Defines a structured return contract (`Developer → Verifier → Auditor` reports) stored under `.context/harness/<sprint>/<role>.json`.
- **`go` skill** — End-to-end feature pipeline. Thirteen phases: worktree setup → `superpowers:writing-plans` → inline harness-protocol section → `plan-review` (auto-accept recommendations) → commit → Codex plan audit → validate/apply findings → execute with strict harness → `simplify` → verify tree clean + run project verification gate → final Codex audit (three labeled buckets: E2E gaps, edge cases, over-engineering) → validate/fix findings → summary. Reuses the Codex session id across the two Codex passes to preserve context.
- **Codex-optional behavior** in `/go` — a readiness probe at startup smoke-checks the Codex CLI; if absent or unauthenticated, phases 6, 7, 11, and the Codex half of 12 are skipped cleanly with a note in the plan's summary. Codex is a second-opinion accelerant, not a gate.
- **Orchestration category** in README — new table section for `go` and `harness-protocol`; mermaid diagram updated with the orchestration layer and invocation edges.
- `CHANGELOG.md` (this file).

### Changed
- `README.md` — installation list extended with `harness-protocol`, `go`, and `tasks-for-sonnet`; repo-structure tree updated; a new usage example showing the `/go` pipeline end-to-end; mermaid diagram includes `tasks-for-sonnet` as Standalone with a "task shape" link from `harness-protocol`.
- `.claude-plugin/marketplace.json` — three new plugin entries (`harness-protocol`, `go`, `tasks-for-sonnet`).
- `harness-protocol` SKILL.md — references `tasks-for-sonnet` as the recommended source of task shape when the implementer is a junior agent; Auditor must enumerate `triggers_satisfied` from the trigger catalog on boundary diffs.
- `retrospective` SKILL.md — adds Step 3.5 "Codex/reviewer feedback synthesis": every retro that closes external-reviewer catches must propose at least one trigger-rule diff to `tasks-for-sonnet` per unique catch class. Closes the loop between catch and future prevention.

## [1.0.0] — 2026-03

Initial public cut of the arsenal. Shipped:

- **Infrastructure:** `web-tool-routing`, `prompt-creator`, `prompt-74`
- **Domain:** `web-research`, `competitor-research`, `researching-consumer-goods`
- **Standalone:** `writing-well`, `plan-review`
