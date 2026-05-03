---
name: tasks-for-sonnet
description: >
  Use when writing, reviewing, or revising implementation tasks for a junior /
  implementation agent (Claude Sonnet, Haiku, or any LLM acting as the
  developer in a harness loop). Converts vague instructions into invariant-first,
  mechanically verifiable tasks with explicit constraints, TDD steps, and
  trigger rules derived from observed failure modes. Trigger phrases:
  "write Sonnet tasks", "implementation handoff", "junior-agent brief",
  "harness sprint plan", "auditor keeps catching things", "tasks for the
  developer agent". Project-agnostic.
---

# Tasks For Junior Implementation Agents

**Posture:** Hard gate + co-execution.

Use this skill to write tasks that a junior implementation agent (Claude Sonnet, Haiku, or any LLM acting as Developer in `harness-protocol`) can execute reliably. These models are capable but follow **explicit instructions** better than implied engineering taste. The job is to remove judgment calls from the implementer and convert product/engineering intent into **falsifiable external invariants**.

This skill is the missing prerequisite to `harness-protocol` and `plan-execution`. Those skills tell you *how* to drive a sprint; this one tells you what a sprint task must contain so the in-loop Verifier and Auditor (also junior models) have a fighting chance against what an external reviewer (Codex, GPT-5, a senior human) routinely catches afterwards.

## When to invoke

Invoke before any of:

- Handing a plan to `plan-execution` or `harness-protocol` for Sonnet to implement.
- Writing or rewriting a sprint's task list, acceptance criteria, or implementation checklist.
- Reviewing a plan that targets a junior implementation agent (`target_executor: claude-sonnet-*`, etc.).
- After an external reviewer (Codex / `/codex` / human) catches something the in-loop harness missed — the catch is a data point for **§ Skill Update Loop**.

## Core Rule

**Every task must say what must be TRUE, not only what mechanism to use.**

Bad:

```md
Use `useTransition` for the CTA.
```

Good:

```md
After tapping the CTA, the user sees a loading spinner for at least one
paint frame before the next view mounts. Verify with CPU throttling or a
deterministic UI test. (Implementation note: `useTransition` alone won't
work without a Suspense boundary — use double-rAF or explicit pending state.)
```

If a fresh verifier cannot prove the criterion from files, tests, commands, or browser behavior, rewrite it before implementation begins.

## Execution Handoff

For plans created by `writing-plans`, `prd`, `implan`, or any other plan-producing skill, use this handoff hierarchy:

```text
plan-execution starts and executes the plan task-by-task
harness-protocol gates each sprint
```

**Recommended plan header (insert as first content after frontmatter):**

```md
> **For junior / agentic workers:** REQUIRED skills, in order:
> 1. Load this skill (`tasks-for-sonnet`) and rewrite each task into
>    "What Must Be True" / "Known Constraints" / "Mechanical Verification"
>    before coding. Apply the trigger catalog (§ 3 below) — do not paraphrase.
> 2. Use `plan-execution` for task-by-task implementation.
> 3. Use `harness-protocol` for sprint Developer → Verifier → Auditor gates.
>
> **Execution model:** `plan-execution` owns task-by-task implementation
> with fresh implementer/reviewer loops. `harness-protocol` owns the sprint
> quality gate with every acceptance criterion scoring at least 9/10.
```

## Task Template

Use this structure for every task handed to a junior agent:

```md
### Task N: <Outcome Name>

**Priority:** Fundamental / Advised / Sweet / Tabled
**Owner:** <implementer agent name>
**Files:**
- Create: `path`
- Modify: `path`
- Test: `path`

#### What Must Be True

- External invariant observable by a user, verifier, test, or command.
- Include the failure mode this prevents.
- Include accessibility / mobile / security / privacy invariants when relevant.

#### Known Constraints

- Platform / provider constraints that are not negotiable.
- Existing repo patterns and source-of-truth files.
- Copy ownership: whether the implementer may or may not edit user-facing copy.
- Dependency rule: whether new dependencies are allowed.
- **Trigger citations from § 3 below** — for every boundary-touching task,
  cite at least one trigger or explicitly state "no trigger applies"
  with a one-line reason.

#### Mechanical Verification

- Exact focused test command.
- Exact `grep` / static check when completeness matters.
- Exact browser / manual check when visual behavior matters.
- Expected failing state before implementation, expected passing state after.

#### Steps

- [ ] Write failing test first.
- [ ] Run the test and confirm it fails for the intended reason.
- [ ] Implement the minimum code to pass.
- [ ] Run focused tests.
- [ ] Run the project's verification gate (see `harness-protocol` § Automated Gates for discovery).
- [ ] Write / update harness report JSON.
- [ ] Commit only after Verifier and Auditor pass.
```

## Known Junior-Agent Failure Modes And Required Fixes

### 1. Mechanism vs invariant

Junior agents implement the named mechanism correctly while missing the user-visible invariant.

```text
IF a task names a mechanism (a hook, an API, a library)
THEN also state the observable invariant and how to verify it.
```

Examples:

- `useTransition` is not enough. State what loading state the user sees.
- "Add a schema" is not enough. State which invalid payloads are rejected.
- "Track an event" is not enough. State which props are allowed and forbidden.
- "Add caching" is not enough. State the staleness budget and the test that proves it.

### 2. Tribal platform constraints

Junior agents may know platform facts but will not always apply them proactively. Spell out constraints explicitly:

- OG / social-preview images must be PNG or JPEG. SVG is not rendered by Twitter, LinkedIn, Slack, or most crawlers.
- Browser image loading must handle cached images. Any `<img>` with an `onLoad` handler also needs a mount-time `img.complete` guard, otherwise cached images never trigger `onLoad`.
- Fetch-triggering buttons need an in-flight ref guard checked **before** the state update. The `disabled` attribute alone is insufficient because it gates on re-render, not on the click event.
- Client input is untrusted. Server must own model selection, completion readiness, allowlists, and final validation.
- Sensitive data (raw email, raw phone, OTPs, transcripts, prompts, provider tokens, captcha tokens) MUST NOT be sent to analytics or logs. Hash identifiers; allowlist properties.
- `useTransition`'s `isPending` is only visible if the state transition is deferred by a Suspense boundary. Without one, use double-`requestAnimationFrame` for guaranteed paint frame visibility.

### 3. Known patterns not applied by default

Trigger conditions tell the implementer **when** a pattern is required.

#### Universal triggers (apply across stacks)

```text
IF any button starts a fetch
THEN add a pre-state-update in-flight ref guard. `disabled` alone is not enough.

IF any image uses onLoad / onError visual state
THEN add an img.complete mount check. Cached images don't fire onLoad.

IF any env var is read in production-relevant code
THEN update env.example AND deployment docs. Grep mechanically:
     `grep -r "process\.env\[" <feature-dir>` count must match env.example count.

IF any numeric env parser is changed
THEN test 0, -1, NaN, "abc", "1abc", "1.5". `parseInt` accepts partials silently.

IF any AI / provider response is returned to client
THEN validate / normalize it before returning 200. Empty / whitespace / malformed
     must be rejected with telemetry.

IF any external call can hang
THEN add timeout (AbortController, ctx.WithTimeout, etc.) or document the
     platform timeout decision.
```

#### Trigger catalog — derived from observed external-reviewer catches

These triggers were each promoted from a real catch where an external reviewer (typically Codex) caught something the in-loop harness missed. Each is stack-agnostic; examples illustrate.

Lineage rule: every trigger here was promoted from a reviewer-caught defect class. **Do not delete a trigger** without first showing the underlying class extinct (≥ 2 sprints with zero recurrence) in the project's findings ledger. See § Skill Update Loop.

##### Client-trust boundary

```text
IF a request schema accepts role / createdAt / id / sessionToken / actorId
THEN OMIT the field from the request schema entirely; the server assigns it.
     Allowlisting is INSUFFICIENT — allowlisted role: 'assistant' still permits
     a forged trusted turn. Allowlisted createdAt still corrupts ordering.
     Test: send the field with a hostile value; assert the request is rejected
     OR the field is ignored and the server-assigned value is used.

IF a request schema accepts modelId / mimeType / providerHint / featureFlag
THEN allowlist server-side from a config / env constant array; reject anything
     not in the allowlist; never forward the client value to the provider as-is.
     For mimeType additionally: byte-level MIME sniff (e.g. `file-type`,
     `python-magic`, `mime-detective`) — the header is untrusted.
     Test: send a value not in the allowlist; assert 400 + canonical error code.
```

Stack examples:

- TypeScript / Zod: `z.object({ messages: z.array(...) /* role omitted */ })`
- Python / Pydantic: define `RequestModel` without `role`; assign in handler.
- Go: define request struct without the field; assign on the server side.
- Ruby / ActiveRecord: use `permitted_params` allowlist; never `params.permit!`.

##### Schema bounds

```text
IF a string field is user-supplied content
THEN apply trim + min(1) + max(N) by default. Only relax with an explicit
     comment stating why empty / whitespace / oversize is acceptable.
     Test: empty, "   " (whitespace-only), and N+1-char inputs each rejected
     at parse time.

IF a number field is a count / duration / size
THEN apply integer + non-negative bounds (or explicit signed bounds with
     a one-line reason for negatives).
     Test: 0, -1, NaN, 1.5, "abc", "1abc" each rejected at parse time.
```

Stack examples:

- Zod: `z.string().trim().min(1).max(2000)`, `z.number().int().nonnegative()`
- Pydantic: `Field(min_length=1, max_length=2000, strip_whitespace=True)`, `conint(ge=0)`
- Joi: `Joi.string().trim().min(1).max(2000).required()`
- Rust / `validator`: `#[validate(length(min=1, max=2000))]`

##### State / enum drift (single source of truth)

```text
IF a column is named status / role / state / kind / phase
THEN model it as a typed enum or CHECK constraint at the DB layer; never raw
     untyped string.
     Cross-check: every code path that sets the column uses a value from a
     single source-of-truth constant array exported from one module. Stub
     fixtures import from the same constant.
     Test: insert with an unknown literal must fail at the DB layer.
```

Stack examples:

- Postgres + Drizzle / Prisma: `pgEnum('status', [...] as const)`; export the array.
- Postgres + raw SQL / SQLAlchemy: `CHECK (status IN ('a','b','c'))` + Python `Enum`.
- MySQL: `ENUM('a','b','c')` column type.
- Application-only (no DB enum): one TypeScript const + a runtime parser.

##### Provider reliability

```text
IF a route calls an external AI / HTTP / RPC provider
THEN wrap in a cancellation primitive with explicit timeout (default 30s);
     validate the response shape with the provider's schema;
     reject empty / whitespace-only payloads before returning success;
     emit a telemetry event on timeout / empty / shape-mismatch.
     Test: mock a provider that hangs (rejected via cancellation), returns ""
     (rejected), and returns malformed payload (rejected).
```

Stack examples:

- Node / fetch: `AbortController` + `AbortSignal.timeout(30_000)`.
- Python / httpx: `timeout=httpx.Timeout(30.0)` + Pydantic response model.
- Go: `context.WithTimeout` + struct unmarshal validation.
- Java / OkHttp: `callTimeout(Duration.ofSeconds(30))`.

##### PII / privacy

```text
IF an analytics / logging event property is derived from user input
THEN the property name MUST be in an allowlist module (one source of truth);
     identifiers MUST be hashed (SHA-256 + project pepper from env), not raw.
     Forbidden raw: email, phone, IP, free-text answers, prompts, provider
     tokens, captcha tokens, distinct IDs derived from PII.
     If the allowlist module does not yet exist, create it as part of the
     same task — seed with [] and the forbidden-list comment.
     Test: snapshot test asserting the allowlist contents; unit test that the
     hash function actually hashes (input ≠ output, deterministic across runs).
```

Stack examples:

- TypeScript: `lib/analytics/allowed-properties.ts` exporting `as const` array.
- Python: `analytics/allowed_properties.py` with `Final[frozenset[str]] = frozenset({...})`.
- Java: enum class `AnalyticsProperty` with allowlist values.

##### Partial-vs-final lifecycle

```text
IF a schema uses a partial / draft variant for an in-progress lifecycle
THEN a paired full / refinement schema MUST exist for the terminal boundary
     (e.g. complete / submit / finalize handler), and the contract MUST be
     stated in a one-line comment on both schemas.
     Test: terminal handler rejects payloads valid against the partial schema
     but missing required terminal fields (e.g. consent: true + email: undefined
     when consent implies email).
```

Stack examples:

- Zod: `BaseSchema` and `BaseSchema.partial()` paired with `BaseSchema.refine(...)` on the terminal route.
- Pydantic: `DraftModel` (all `Optional`) + `FinalModel` extending with `model_validator(mode='after')`.

### 4. Non-mechanical completeness

Vague completeness tasks rely on the implementer's memory. Replace them with grepable / commandable checks.

Bad:

```md
Document env vars.
```

Good:

```md
Run `rg "process\.env\[" path/to/feature`. Every production-relevant env read
must have a matching entry in `.env.example` and deployment docs. Counts must
match: `<feature env count>` reads → `<feature env count>` example entries.
```

## Acceptance Criteria Rules

Each acceptance criterion must be:

- **Falsifiable.** A fresh verifier marks pass/fail without knowing intent.
- **External.** Describes behavior, contract, or measurable state — not implementation.
- **Mechanical.** Includes a test, command, static check, or browser check.
- **Negative-case aware.** Includes at least one failure path for validation / security work.
- **PII-aware.** Explicitly forbids sensitive props where analytics or AI calls are involved.

Avoid criteria that say:

- "Implement correctly"
- "Make it nice"
- "Add support"
- "Handle edge cases"
- "Use X"

Replace with:

- exact behavior
- exact edge cases
- exact source-of-truth file
- exact expected output
- exact verification command

## Sprint Rules

For multi-task junior-agent work:

1. Split work into sprints that produce testable behavior.
2. Each sprint runs Developer → Verifier → Auditor (see `harness-protocol`).
3. Developer writes failing tests first.
4. Verifier maps tests to acceptance criteria.
5. Auditor scores every criterion; below 9/10 fails the sprint.
6. **Auditor MUST also enumerate `triggers_satisfied: [{trigger_id, file, line}]`** for every trigger in § 3 that applies to the diff. Empty enumeration on a boundary diff is an audit failure — the auditor either didn't check or the implementer didn't apply.
7. Store harness reports under `.context/harness/<scope>/<sprint>/{developer,verifier,auditor}.json`.
8. Stop after each sprint for external review when the plan says so.

Do not batch multiple sprints just because tasks look small. Batching hides drift.

## Sub-Agent Dispatch — Required Reads

When spawning a sub-agent (Verifier, Auditor, attack-pass) for boundary work, the dispatch prompt MUST include explicit absolute paths to read. Sub-agents do **not** auto-inherit project rules or this skill — they only see CLAUDE.md plus what's in their prompt:

```
Read these files in order before responding:
1. <abs-path>/skills/tasks-for-sonnet/SKILL.md (full file, especially § 3)
2. <project>/.claude/rules/sonnet-handoff.md (if it exists)
3. <the diff / task / plan under review>

For each trigger in § 3 of tasks-for-sonnet that applies to the diff:
determine whether it is satisfied. Output BLOCKER / MAJOR / MINOR per finding
with file:line citations. Anti-fabrication: if no trigger applies, say so.
```

Resolve absolute paths from `git rev-parse --show-toplevel` for the project root and from the skill cache (typically `~/.claude/plugins/cache/skill-arsenal/`) for the skill — never assume the sub-agent's working directory.

## Skill Update Loop

This skill is a living artifact. Every external-reviewer catch on the implementer's work is a data point — if a reviewer caught a class of bug that the in-loop harness (Developer / Verifier / Auditor — all the same junior model) missed, the same junior writing the next sprint will miss it again unless the trigger is captured here.

**After every external review** (whether `/go` Codex pass, `/codex` on-the-side, senior human review, or any other independent audit):

1. Open the project's findings ledger (this skill is agnostic to the format — examples: `docs/retro/codex-findings/<period>.md`, `audits/<date>.md`, GitHub Issues with a `caught-by-review` label).
2. For each entry where an external reviewer caught a class of bug **and** an in-loop role (Verifier or Auditor) had previously passed the same scope, the difference is what the in-loop harness missed.
3. Propose a trigger rule for this skill in the same change-set that closes the finding. Add it under § 3 with the originating finding cited inline (e.g., `[origin: <ledger-file> <finding-id>]`).
4. If the class already has a trigger and the reviewer caught it again, treat it as a sharper trigger needed — revise the existing trigger; do not duplicate.

**When to retire a trigger:** only after ≥ 2 sprints with zero recurrence of the class in the ledger. Removing a trigger without that evidence reopens a known catch class.

**Forcing function (project-side):** projects using this skill should add a "skill update loop" clause to their codex/audit-integration rule (e.g., `.claude/rules/codex-integration.md`) making the trigger-rule diff mandatory at retro time. Without that forcing function, this loop is a should, not a must — and drift is the default. The retro is the audit point.

## Prompt Pattern For Handing A Plan To A Junior Agent

```text
Use plan-execution to execute <plan-file>.
Use harness-protocol for every sprint gate.
Before coding each task, rewrite it into:
- What Must Be True
- Known Constraints (cite at least one trigger from tasks-for-sonnet § 3
  for every boundary-touching task — server route, schema, AI/HTTP call,
  analytics, file upload, auth — or state "no trigger applies")
- Mechanical Verification

Do not use orchestration skills like /go unless explicitly authorized.
Do not rewrite product copy unless the task explicitly permits it.
Write failing tests first. Stop when blocked instead of guessing.
```

## Quick Review Checklist

Before giving a task to a junior agent, check:

- [ ] Does it state observable behavior, not only implementation mechanism?
- [ ] Are platform constraints explicit?
- [ ] Are known proactive patterns named with trigger conditions?
- [ ] Is completeness grepable or testable?
- [ ] Are copy ownership and dependency permissions clear?
- [ ] Are privacy / security forbidden fields listed?
- [ ] Is the exact verification command included?
- [ ] Does the task say when to stop and ask?
- [ ] **For boundary-touching tasks:** is at least one § 3 trigger cited, or "no trigger applies" stated explicitly?

If any item is missing, revise the task before execution.

## See also

- `harness-protocol` — sprint quality gates that consume the tasks this skill produces.
- `plan-execution` (skill from `superpowers` or equivalent) — task-by-task execution loop.
- `writing-plans`, `prd`, `implan` — plan-producing skills whose output is rewritten through this skill before junior-agent execution.
- `retrospective` — the audit point where new triggers get promoted into § 3 from reviewer catches.
- `devil-advocate` — adversarial review that complements external reviewers in the catch loop.
