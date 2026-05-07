---
name: tasks-for-sonnet
description: >
  Use BEFORE dispatching any Task / Agent / sub-agent (Sonnet, Haiku,
  general-purpose, Explore) — consult § Placement Guide to decide whether
  Sonnet fits the work, § Dispatch Hygiene for the prompt contract, and
  § Task Template if the sub-agent will execute code. The skill is the
  orchestrator's manual for using Sonnet as Hands: when to send work, when
  not to, and how to shape the prompt so Sonnet performs reliably. Also use
  when writing tasks for a junior implementation agent in a harness loop,
  when deciding which model for a sub-task, when planning parallel agent
  work, or when an external reviewer keeps catching things the in-loop
  harness missed. Trigger phrases: "dispatch sub-agent", "spawn agent",
  "before sub-agent", "which model", "should I use sonnet", "delegate to
  sonnet", "parallel agents", "scout swarm", "write Sonnet tasks",
  "implementation handoff", "junior-agent brief", "harness sprint plan",
  "auditor keeps catching things", "tasks for the developer agent".
  Project-agnostic.
---

# Tasks For Junior Implementation Agents

**Posture:** Hard gate + co-execution.

Use this skill as the orchestrator's manual for using a junior model (Claude Sonnet, Haiku, or any smaller LLM) as **Hands** — both deciding **whether** to dispatch a sub-agent at all, and **how** to shape the prompt so the work lands reliably. Junior models are capable but follow **explicit instructions** better than implied engineering taste. The job is to remove judgment calls from the implementer and convert product/engineering intent into **falsifiable external invariants**.

This skill is the missing prerequisite to `harness-protocol` and `plan-execution`. Those skills tell you *how* to drive a sprint; this one tells you what a sprint task must contain — and where in your pipeline a junior agent earns its keep at all — so the in-loop Verifier and Auditor (also junior models) have a fighting chance against what an external reviewer (Codex, GPT-5, a senior human) routinely catches afterwards.

## Brain ↔ Hands ↔ Scouts

A useful mental model for any orchestrator picking which model runs which piece of work:

- **Brain** (Opus / GPT-5 / senior human) — encodes judgment, makes architecture decisions, writes the spec in the template this skill defines. The brain owns the *what* and the *why*.
- **Hands** (Sonnet / Haiku / any junior LLM) — executes against invariants. Reliable when given the template; unreliable when given implied taste. The hands own the *how*, only when the *what* is fully specified.
- **Scouts** (parallel cheap junior agents) — run BEFORE the brain commits to a plan. Mapping, single-concern review, version fact-checks, multi-file synthesis. Cheap, parallelizable, fresh-context. The scouts enrich the plan; they never write production code.

Read § Placement Guide to decide which role fits the work in front of you. Read § Dispatch Hygiene before pressing the dispatch button. Read § Task Template if the sub-agent will be writing code — but first ask whether it should.

## Placement Guide — where Sonnet earns its keep

Empirically, junior models add the most value as scouts, reviewers, verifiers, and synthesizers — not as writers of application code. Use this section to decide which role fits before you dispatch.

### Use Sonnet for

- **Mapper / scout** — `Explore` agent or equivalent, tight scope (one module / controller / component / package), word cap. Output is `file:line` citations, not raw code dumps. Run BEFORE the brain commits to a plan.
- **Single-concern reviewer trio** — three reviewers in one parallel dispatch (typical concerns: reuse / quality / efficiency, or correctness / security / performance). Each prompt explicitly tells the agent the other concerns are out of scope. Single message, multiple Task calls.
- **Verifier with PASS/FAIL** — pinned commit hash or absolute paths, fresh-context opener, verdict required. The verifier does not re-judge severity; it confirms or denies.
- **Multi-file synthesis** — `session-analyzer` or equivalent for transcripts, sessions, or any "many small inputs → one digest" workload. Junior models excel at structured digestion.
- **Version / API fact-check** — `WebFetch` + junior model for any version-sensitive or post-cutoff claim. Cheap insurance against training-data drift.
- **Cross-surface scout** — when work spans repos / packages / surfaces, one scout per surface, parallel, before the Developer agent.
- **Fully-templated scaffolding** — fixtures, factories, migrations from a complete spec — only with an explicit `carve_out: true` flag in the harness JSON and a one-line rationale. Without that flag, junior-as-Developer is a violation of the standard harness rule (Brain writes; Hands review and verify).

### Don't use Sonnet for

- **Application code requiring judgment** — controllers, models with logic, business rules, anything where the *how* is not fully specified by the *what*. The brain writes. If the task tempts you to write "use X correctly," you don't have a Sonnet task — you have a brain task.
- **Sub-5-line tasks** — environment fixes, single Bash edits, single file reads. Direct tool call from the parent is faster than a sub-agent dispatch.
- **Iterating the same artefact >2× per session** — if you find yourself dispatching v2 → v3 → v4 of "apply these new findings," collapse into a single "apply all" pass. Plan-versioning treadmills hide drift.
- **Single-fact lookups inside the parent's reach** — if `Bash` / `WebFetch` from the parent works, skip the sub-agent overhead.
- **Dispatch before prerequisites are confirmed** — paths, permissions, branch state, commit hashes. A cancelled scout run is pure cost.
- **Tasks you'd retry without first reading the previous result** — re-dispatching the same prompt with no new information is a code smell. Read the prior return; revise the prompt; then retry.

### Scout Swarm pattern

For non-trivial tasks (≥3 files, ≥1 boundary touched, or any new module), dispatch a single message of parallel scouts BEFORE the brain commits to the plan. Default pack:

- 1 **Mapper** per module touched — surface area, key call sites, existing utilities to reuse.
- 1 **Reviewer trio** for the merged plan or the most recent diff — non-overlapping concerns.
- 1 **Version fact-checker** if the plan has any version-sensitive claim.
- (Optional) 1 **Cross-surface scout** per repo/package if work spans surfaces.
- (Optional) 1 **Synthesis scout** if the plan rests on prior session/transcript context.

Output enriches the plan as a "Reconnaissance" section. Scouts never write production code. Skip the swarm for trivial scope (≤5 lines, ≤2 files, single-fact lookup).

### Plan-Time Tagging

When an orchestrator (e.g., `/go`) decides Sonnet eligibility once, on the plan, instead of implicitly at dispatch time, use this canonical inline marker so the decision is visible and reviewable:

```markdown
<!-- sonnet_eligible: true | false — rationale: <one line citing § Placement Guide row> -->
```

Place the marker on its own line directly under each task header. Plan-review skills should treat any `sonnet_eligible: true` task that touches a § 3 trigger (client-trust, schema bounds, state drift, provider reliability, PII, partial-vs-final, live runtime path) or any money / auth / migration / >5-file scope as a tagging error and recommend `false`. Auditors never override the marker silently — bad markers get re-tagged in a visible commit.

This is the public contract; any orchestrator (not just `/go`) can adopt it. The harness loop reads the marker per task at sprint dispatch time and pairs it with § Dispatch Hygiene to shape the brief.

## Dispatch Hygiene

Before dispatching any junior sub-agent, verify the prompt meets this contract. These rules were each promoted from observed failure modes; treat them as load-bearing.

- **`model: sonnet` explicit on every dispatch.** `general-purpose` without an explicit `model:` field silently inherits the parent's model (typically Opus) — an invisible 3–5× cost regression with no observable signal in the dispatch. Always set the field; never rely on inheritance.
- **Word cap stated in the prompt.** Default 600 words; 400 for small directories. Without a cap, junior models pad output and bury the answer.
- **Fresh-context opener for reviewers and verifiers.** Begin with: *"You do NOT know the parent's intent. Read the diff cold. Find BLOCKERs, not praise."* Without this, junior reviewers tend to rubber-stamp.
- **Pinned commit hash or absolute file paths for verifiers.** Sub-agents do not auto-inherit the parent's working directory or branch state. State the targets explicitly. Require a PASS/FAIL verdict.
- **One "apply all" pass over N versioned passes.** If you'd run the same prompt with the next finding queued, fold the findings into a single dispatch. Sequential v2 → v3 → v4 versioning is anti-pattern.
- **Read the previous result before retrying.** Never re-issue a prompt without reading what the prior dispatch returned. Most retry failures are caused by not noticing the first result already had the answer.
- **Pre-flight before dispatch.** Confirm permissions, paths, branch, commit hashes BEFORE launching. Cancelled scout runs cost real tokens.
- **Parallel dispatches in one message.** When concerns are non-overlapping, send all Task calls in a single message — not sequentially. Each prompt explicitly names its concern and tells the agent the others are out of scope.

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

Trigger conditions tell the implementer **when** a pattern is required. The full IF/THEN rules and stack examples live in `references/trigger-catalog.md`. Read that file when you need to:

- Cite a trigger in a task's *Known Constraints* section for boundary work.
- Enumerate `triggers_satisfied: [{trigger_id, file, line}]` as Auditor on a sprint diff.
- Promote a new trigger after an external reviewer catches a class the in-loop harness missed.

The catalog has two layers:

**Universal triggers** — concise patterns that apply almost everywhere (button starts fetch → in-flight ref guard; image onLoad → img.complete mount check; env var read → env.example update with grep count match; numeric env parser → test 0/-1/NaN/partials; AI response → validate before 200; external call → timeout primitive).

**Trigger catalog** — each entry promoted from a real defect class an external reviewer caught. One-line summaries:

- **Client-trust boundary** — server assigns; never trust client-supplied `role` / `createdAt` / `sessionToken` / `actorId`. For `modelId` / `mimeType` / `providerHint`, server-side allowlist + byte-level MIME sniff.
- **Schema bounds** — strings get `trim + min(1) + max(N)` by default; numbers get `integer + non-negative` (or explicit signed bounds with reason). Test rejection of empty / whitespace / oversize / NaN / partials.
- **State / enum drift** — `status` / `role` / `state` / `kind` / `phase` modelled as typed enum or CHECK constraint at the DB layer, with a single source-of-truth constant array. Insert with unknown literal must fail.
- **Provider reliability** — external AI / HTTP / RPC calls wrapped in cancellation + explicit timeout, response shape validated, empty / whitespace rejected, telemetry on timeout / empty / shape-mismatch.
- **PII / privacy** — analytics property names allowlisted in one module; identifiers hashed (SHA-256 + project pepper); raw email / phone / IP / prompts / tokens forbidden.
- **Partial-vs-final lifecycle** — partial / draft schema paired with full / terminal schema; terminal handler rejects payloads valid against partial but missing required terminal fields.
- **Live runtime path** — new abstraction / schema / adapter / contract requires at least one test exercising the live production path through the public handler / route / component, failing if the runtime stays on the old path. Includes seven instantiations: end-to-end wiring, old-contract retirement, prompt/schema/renderer lockstep, source-of-truth extraction, spec completeness for input fields, negative-only checks insufficient, live path over unit path.

For full IF/THEN rules and stack examples (TypeScript / Python / Go / Rails), read `references/trigger-catalog.md`.

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
1. <abs-path>/skills/tasks-for-sonnet/SKILL.md (full file, especially § 3 index)
2. <abs-path>/skills/tasks-for-sonnet/references/trigger-catalog.md (full IF/THEN
   rules and stack examples — required for boundary work)
3. <project>/.claude/rules/sonnet-handoff.md (if it exists)
4. <the diff / task / plan under review>

For each trigger in the trigger catalog that applies to the diff: determine
whether it is satisfied. Output BLOCKER / MAJOR / MINOR per finding with
file:line citations. Anti-fabrication: if no trigger applies, say so.
```

Resolve absolute paths from `git rev-parse --show-toplevel` for the project root and from the skill cache (typically `~/.claude/plugins/cache/skill-arsenal/`) for the skill — never assume the sub-agent's working directory. The reference file is at `<skill-path>/references/trigger-catalog.md`.

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
