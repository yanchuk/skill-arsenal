---
name: tasks-for-sonnet
description: >
  Use when older plans, commands, or skills refer to tasks-for-sonnet,
  Sonnet task briefs, sonnet_eligible markers, or the historical
  trigger catalog for junior implementation agents.
---

# Tasks For Sonnet Compatibility Alias

`tasks-for-sonnet` is now a compatibility alias. Use `agent-task-briefs`
for new work.

This alias exists for one release so older plans and orchestration skills can
still resolve:

- `tasks-for-sonnet`
- `sonnet_eligible`
- `tasks-for-sonnet § 3`
- `tasks-for-sonnet/references/trigger-catalog.md`

## Required Handoff

When this skill is invoked, load `agent-task-briefs` next and follow it as the
canonical source of truth when available. If `agent-task-briefs` is not
installed, use the compatibility brief rules below so single-plugin legacy
installs still behave safely.

For Codex, treat old "Sonnet" wording as "worker-agent lane." Use
`agent-task-briefs` § Runtime Model Lanes to decide whether a task belongs in
the parent model, `worker`, `explorer`, or a custom agent such as a bounded
`gpt-5.3-codex-spark` worker.

Treat these legacy terms as aliases:

| Legacy term | Canonical term |
|-------------|----------------|
| Sonnet task | worker-agent task |
| Sonnet eligibility | worker-agent eligibility |
| `sonnet_eligible` | `worker_agent_eligible` |
| `tasks-for-sonnet § 3` | `agent-task-briefs §3` |

## Compatibility Rules

- Existing `sonnet_eligible: true | false` markers remain valid.
- New plans should use `worker_agent_eligible: true | false`.
- Existing references to this skill's trigger catalog should read
  `agent-task-briefs/references/trigger-catalog.md` when available.
- Do not add new behavior here; update `agent-task-briefs` instead.

## Compatibility Brief Rules

Use these rules only when `agent-task-briefs` cannot be loaded:

- Every delegated task states observable behavior, not only a mechanism.
- Every task includes Known Constraints and Mechanical Verification.
- Boundary work cites at least one trigger from `references/trigger-catalog.md`,
  or explicitly says "no trigger applies" with a reason.
- Reviewers and verifiers get a fresh-context opener, pinned paths or commit
  hash, one concern, and a word cap.
- Keep judgment-heavy application code in the parent or strongest available
  model; delegate scouts, narrow reviewers, verifiers, synthesis, version
  fact-checks, and fully specified scaffolding.
- Existing `sonnet_eligible` markers stay valid; new plans should emit
  `worker_agent_eligible`.

Minimum task shape:

```md
### Task N: <Outcome>

#### What Must Be True
- <observable invariant and failure mode prevented>

#### Known Constraints
- <source of truth / platform constraint / trigger citation>

#### Mechanical Verification
- <exact command, static check, or browser check>
```

## See Also

- `agent-task-briefs` — canonical provider-neutral task brief skill.
- `agent-task-briefs/references/trigger-catalog.md` — canonical trigger catalog.
