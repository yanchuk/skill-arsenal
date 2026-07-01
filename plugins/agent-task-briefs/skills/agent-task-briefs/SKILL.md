---
name: agent-task-briefs
description: >
  Use before delegating work to a subagent, worker model, scout, verifier,
  reviewer, or junior implementation agent; when writing task briefs,
  acceptance criteria, harness sprint plans, or agent handoffs; when deciding
  whether delegated execution is appropriate; when assigning model lanes for
  Codex, Claude, OpenCode, or another runtime; or when reviewer findings show
  that prior agent briefs missed concrete invariants.
---

# Agent Task Briefs

Use this skill to turn intent into tasks a fresh worker agent can execute and
a fresh verifier can judge. It is provider-neutral: Claude Code, Codex,
OpenCode, and other agent runtimes are adapters. The task contract is the
same everywhere.

## Runtime Model Lanes

The parent agent owns model assignment before dispatch. Pick the smallest
runtime lane that can satisfy the invariant, then make the lane explicit in
the brief.

| Lane | Use for | Examples |
|------|---------|----------|
| **Brain** | architecture, product judgment, ambiguous tradeoffs, final sign-off | strongest available parent model, senior human |
| **Worker** | scoped implementation after invariants, files, and tests are specified | Codex `worker`, Claude Sonnet 5, OpenCode worker |
| **Scout** | read-heavy mapping, single-concern review, version/API checks, synthesis | Codex `explorer`, Claude Explore/general-purpose |
| **Specialist** | browser debugging, docs research, security review, migration audit | named custom agent with constrained tools |

Do not equate "junior" with "bad." A smaller worker model is useful when the
task is bounded and mechanically verifiable. Use the strongest model only when
the task still needs judgment.

### Worker Capability Is Rising

Worker-lane models keep closing on the Brain lane: a current worker model
(e.g. Claude Sonnet 5) can self-check its own output and finish multi-step
tool-and-coding tasks where earlier worker models would halt, at lower cost and
often with an effort/reasoning-effort control that trades cost for depth. That
shifts three placement decisions — and the shift holds for any worker model at
this tier, not a named one:

- **Widen the Worker lane; keep the contract.** More multi-step, self-checking,
  agentic implementation is now worker-eligible — but self-checking is not a
  substitute for a falsifiable acceptance criterion. You still cannot read
  intent out of a passing self-check, so invariant-first briefs and mechanical
  verification still decide placement.
- **Match the effort dial to the bound, not the model tier.** When the runtime
  exposes an effort or reasoning-effort control (e.g. Codex
  `model_reasoning_effort`, per-model effort levels), set it from the task's
  bound — low for mechanical scaffolding, higher for ambiguous edges — before
  reaching for a larger model.
- **Strong-at-general is not strong-at-everything.** A worker model can match a
  flagship model on everyday coding yet stay materially weaker on a specialized
  high-stakes lane — dangerous-capability and security-exploit work is a known
  gap. Keep security review, migration audits, and similar specialist work in
  the Brain or Specialist lane even when the worker is strong at day-to-day
  implementation.

### Codex Adapter

Codex supports built-in subagents (`default`, `worker`, `explorer`) and custom
agents under `~/.codex/agents/` or `.codex/agents/`. Custom agents can set
`model`, `model_reasoning_effort`, `sandbox_mode`, MCP servers, and skill
config. This lets a plan send scout or small implementation work to a cheaper
model while keeping judgment-heavy work in the parent.

Example Codex custom agent for a bounded worker:

```toml
name = "spark_worker"
description = "Small implementation worker for bounded tasks with explicit files and tests."
model = "gpt-5.3-codex-spark"
model_reasoning_effort = "medium"
developer_instructions = """
Implement only the assigned task.
Keep unrelated files untouched.
Return files changed, tests run, and any blocker.
"""
```

Use Codex subagents only when explicitly asked or when the plan authorizes
delegation. Keep `agents.max_depth` shallow unless recursive delegation is a
deliberate design choice.

## Core Rule

Every delegated task must say what must be true, not only what mechanism to
use.

Bad:

```md
Use `useTransition` for the CTA.
```

Good:

```md
After tapping the CTA, the user sees a loading spinner for at least one paint
frame before the next view mounts. Verify with CPU throttling or a deterministic
UI test. If no Suspense boundary defers the transition, use explicit pending
state or double `requestAnimationFrame`.
```

## Placement Guide

Use worker agents for:

- **Scouting:** map one module, surface, or package before the parent commits to a plan.
- **Single-concern review:** correctness, security, performance, reuse, or UX writing as separate reviews.
- **Verification:** PASS/FAIL checks with pinned paths, commit hashes, commands, and evidence.
- **Synthesis:** many small inputs into one digest, transcript summary, or findings ledger.
- **Version fact-checks:** current API or platform behavior, with source citations.
- **Fully specified scaffolding:** fixtures, migrations, or mechanical adapters with no design judgment left.

Keep work in the parent agent for:

- application code where the "how" still requires architecture or product judgment;
- sub-5-line fixes, single fact lookups, and simple file reads;
- tasks you would retry without first reading the previous result;
- any dispatch where paths, branch state, permissions, or verification commands are still unknown.

### Plan-Time Marker

When a plan decides delegation once instead of at dispatch time, use:

```markdown
<!-- worker_agent_eligible: true | false — rationale: <one line citing Placement Guide> -->
```

Accept legacy `sonnet_eligible: true | false` markers during the
`tasks-for-sonnet` compatibility window, but new plans should use
`worker_agent_eligible`.

## Dispatch Hygiene

Before spawning a worker agent, verify the brief has:

- explicit runtime target when the platform supports it (`model`, `subagent_type`, custom-agent name, or equivalent);
- a word cap, usually 400-600 words for scouts and reviewers;
- a fresh-context opener for reviewers: "You do not know the parent's intent. Read the target cold. Find blockers, not praise.";
- pinned commit hash or absolute file paths for verification;
- one concern per reviewer or scout;
- all parallel, independent reviews launched together;
- no repeated retry unless the previous result was read and the prompt changed.

Use model names only as examples. "Sonnet", "Haiku", "GPT", "Spark", or
"Codex" are runtime choices, not the skill's domain model.

## Task Template

```md
### Task N: <Outcome Name>

**Priority:** Fundamental / Advised / Sweet / Tabled
**Owner:** <agent role or parent>
**Files:**
- Create: `path`
- Modify: `path`
- Test: `path`

#### What Must Be True

- Observable behavior, contract, or state.
- Failure mode this prevents.
- Accessibility, mobile, security, or privacy invariant when relevant.

#### Known Constraints

- Platform or provider constraints that are not negotiable.
- Existing source-of-truth files and local patterns.
- Copy ownership and dependency policy.
- Trigger citations from §3, or "no trigger applies" with a reason.

#### Mechanical Verification

- Exact focused command.
- Exact static check when completeness matters.
- Exact browser or manual check when visual behavior matters.
- Expected failing state before the fix and expected passing state after.

#### Steps

- [ ] Write the failing test first.
- [ ] Run it and confirm it fails for the intended reason.
- [ ] Implement the minimum change.
- [ ] Run focused tests.
- [ ] Run the project verification gate.
- [ ] Produce a verifier-readable report.
```

## §3 Known Patterns Not Applied By Default

Trigger conditions tell the implementer when a pattern is required. Full
IF/THEN rules and examples live in `references/trigger-catalog.md`.

Use the catalog when you need to:

- cite a trigger in a task's Known Constraints section;
- enumerate `triggers_satisfied: [{trigger_id, file, line}]` on a diff;
- promote a new trigger after an external reviewer catches a repeated class of miss.

Trigger summaries:

- **Client-trust boundary:** server assigns trusted fields; client hints get allowlists and validation.
- **Schema bounds:** strings, numbers, enums, and terminal payloads get explicit limits and rejection tests.
- **State / enum drift:** state names live in one typed source of truth and unknown literals fail.
- **Provider reliability:** external calls get timeouts, cancellation, shape validation, and telemetry.
- **PII / privacy:** analytics and logs use allowlists; raw sensitive data is forbidden.
- **Partial-vs-final lifecycle:** draft and terminal schemas are separate, and terminal handlers reject partial payloads.
- **Live runtime path:** new abstractions must be exercised through the production path, not only unit seams.

Read `references/trigger-catalog.md` for the full trigger set before reviewing
boundary work.

## Acceptance Criteria Rules

Each criterion must be:

- **Falsifiable:** a fresh verifier can mark pass or fail.
- **External:** it describes behavior, contract, or measurable state.
- **Mechanical:** it includes a test, command, static check, or browser check.
- **Negative-case aware:** validation and security work include rejection cases.
- **PII-aware:** analytics, AI calls, and logs list forbidden fields.

Avoid "implement correctly", "handle edge cases", "make it nice", and "use X".
Replace them with exact behavior, exact source-of-truth files, and exact checks.

## Sprint Rules

For multi-task delegated work:

1. Split work into sprints that produce testable behavior.
2. Run Developer -> Verifier -> Auditor or the platform's equivalent gate.
3. Developer writes failing tests first.
4. Verifier maps tests to acceptance criteria.
5. Auditor scores every criterion; below the project's threshold fails the sprint.
6. Boundary diffs include `triggers_satisfied` for every applicable §3 trigger.
7. Store reports where the project expects them.

Do not batch sprints just because tasks look small. Batching hides drift.

## Required Reads For Subagents

For boundary work, include explicit paths in the dispatch prompt. Subagents do
not reliably inherit project rules or skill context.

```text
Read these files in order before responding:
1. <abs-path>/skills/agent-task-briefs/SKILL.md
2. <abs-path>/skills/agent-task-briefs/references/trigger-catalog.md
3. <project instructions file, if any>
4. <the diff / task / plan under review>

For each trigger that applies to the diff, decide whether it is satisfied.
Return BLOCKER / MAJOR / MINOR findings with file:line citations. If no trigger
applies, say so.
```

## Skill Update Loop

Every independent-review catch is a data point. If a reviewer caught a class of
bug that an in-loop verifier or auditor passed, add or sharpen a trigger in this
skill as part of the same change set. Do not duplicate existing triggers.

Retire a trigger only after at least two relevant sprints with no recurrence.

## Prompt Pattern

```text
Execute <plan-file> task by task.
Use the project's harness or review gate for every sprint.
Before coding each task, rewrite it into:
- What Must Be True
- Known Constraints (cite at least one §3 trigger for boundary work, or state "no trigger applies")
- Mechanical Verification

Do not invoke broader orchestration workflows unless authorized.
Do not rewrite product copy unless the task permits it.
Write failing tests first. Stop when blocked instead of guessing.
```

## Quick Check

- [ ] Observable behavior, not only mechanism.
- [ ] Constraints are explicit.
- [ ] Boundary triggers are cited or ruled out.
- [ ] Completeness is grepable or testable.
- [ ] Copy and dependency ownership are clear.
- [ ] Privacy and security forbidden fields are listed.
- [ ] Exact verification command is included.
- [ ] The task says when to stop and ask.

## See Also

- `harness-protocol` for sprint quality gates.
- `tasks-for-sonnet` for temporary backward compatibility.
- `retrospective` for promoting reviewer catches into trigger updates.
- `devil-advocate` for adversarial review.
