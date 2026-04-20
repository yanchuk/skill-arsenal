# Changelog

All notable changes to skill-arsenal are tracked here. Format loosely follows
[Keep a Changelog](https://keepachangelog.com/en/1.1.0/) and [SemVer](https://semver.org/).

## [Unreleased]

### Added
- **`harness-protocol` skill** — Orchestrator → Developer → Verifier → Auditor pattern for multi-sprint work. Project-agnostic; discovers the project's verification gate from `.claude/rules/testing-gates.md`, `package.json` scripts, or `Makefile`. Hard >9/10 per-criterion threshold. Generator never self-evaluates; intra-sprint triad is strictly sequential; within a single role, independent subtasks may fan out via `superpowers:dispatching-parallel-agents`. Defines a structured return contract (`Developer → Verifier → Auditor` reports) stored under `.context/harness/<sprint>/<role>.json`.
- **`go` skill** — End-to-end feature pipeline. Thirteen phases: worktree setup → `superpowers:writing-plans` → inline harness-protocol section → `plan-review` (auto-accept recommendations) → commit → Codex plan audit → validate/apply findings → execute with strict harness → `simplify` → verify tree clean + run project verification gate → final Codex audit (three labeled buckets: E2E gaps, edge cases, over-engineering) → validate/fix findings → summary. Reuses the Codex session id across the two Codex passes to preserve context.
- **Codex-optional behavior** in `/go` — a readiness probe at startup smoke-checks the Codex CLI; if absent or unauthenticated, phases 6, 7, 11, and the Codex half of 12 are skipped cleanly with a note in the plan's summary. Codex is a second-opinion accelerant, not a gate.
- **Orchestration category** in README — new table section for `go` and `harness-protocol`; mermaid diagram updated with the orchestration layer and invocation edges.
- `CHANGELOG.md` (this file).

### Changed
- `README.md` — installation list extended with `harness-protocol` and `go`; repo-structure tree updated; a new usage example showing the `/go` pipeline end-to-end.
- `.claude-plugin/marketplace.json` — two new plugin entries (`harness-protocol`, `go`).

## [1.0.0] — 2026-03

Initial public cut of the arsenal. Shipped:

- **Infrastructure:** `web-tool-routing`, `prompt-creator`, `prompt-74`
- **Domain:** `web-research`, `competitor-research`, `researching-consumer-goods`
- **Standalone:** `writing-well`, `plan-review`
