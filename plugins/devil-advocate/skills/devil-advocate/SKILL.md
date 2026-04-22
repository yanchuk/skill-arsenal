---
name: devil-advocate
description: >
  Use when the user types /devil-advocate, /devils-advocate, says "play
  devil's advocate", "attack this plan", "adversarial review", "find holes
  in", "red-team this", or before any high-blast-radius change (money, auth,
  security, migrations, >5 files). Distinct from plan-review (which surveys,
  not attacks).
---

# /devil-advocate — adversarial independent reviewer

Attack a target artifact from a fresh context. The output is a punch
list of BLOCKER / MAJOR / MINOR findings, each with a concrete edit.
The goal is **signal**: catch the thing the survey-style reviewer
missed.

## Independence — honest framing

This skill spawns a sub-agent via `Agent({subagent_type: "general-purpose", ...})`. The sub-agent:

- **Gets** a fresh conversation window — no prior turn history from
  the parent, no knowledge of the author's framing or reasoning.
- **Inherits** (unavoidably, per Claude Code's runtime) CLAUDE.md,
  `.claude/rules/`, `~/.claude/rules/`, and auto-memory.

"Independence" here means: the sub-agent reads the target artifact
**fresh**, forms its own opinion, and isn't anchored by the parent's
conclusions. That's weaker than "running on a pristine install,"
stronger than "the parent grading itself."

## Input contract

```
/devil-advocate --target <path>
                [--attack <comma-separated vectors>]
                [--severity blocker,major,minor]
                [--word-cap 700]
                [--context-note "<1-2 sentence situational note>"]
```

- `--target` — required. Path to the artifact (plan, diff, RFC, design doc).
- `--attack` — optional. 5–10 specific vectors. If omitted, infer 5–8 from the target.
- `--severity` — optional. Allowed severities in output. Default: all three.
- `--word-cap` — optional. Response size ceiling. Default: 700.
- `--context-note` — optional. A short *situational* brief (e.g., "this is a disclosure-layer plan, v5"). Do NOT pass the author's analysis.

## Guardrails (non-negotiable)

1. **Pass only the target + minimal briefing.** Do not paste prior
   analysis. Do not summarize the author's reasoning. The sub-agent
   should form opinions by reading the artifact itself.
2. **Enumerate attack vectors explicitly.** Concentration beats
   breadth. Generic "review this" gets generic results.
3. **Require "if X is fine, say so".** This anti-fabrication rule
   stops the sub-agent from padding the output with invented
   concerns. Low finding count on a well-written artifact is the
   right outcome.
4. **Require concrete edits.** Every finding must include: file path
   (or section), severity, the underlying fact that makes it wrong,
   and a proposed revision (1-2 sentences). "Reconsider X" is not
   allowed — it must say what to change.
5. **Enforce the word cap.** Signal over volume.

## Severity rubric the sub-agent must use

- **BLOCKER** — ship will break / leak / violate a constraint. Fix
  before proceeding.
- **MAJOR** — design rework or unverified premise. Fix before
  proceeding OR document accepted risk in the artifact.
- **MINOR** — clarification, wording, polish. Can defer.

## Step 1: Read the target

Read the full artifact (up to 2000 lines). If longer, read the first
2000 + the last 500 and note truncation.

## Step 2: Derive or accept attack vectors

If user passed `--attack`, use those verbatim. Otherwise, infer 5–8
based on artifact type:

- **Plans / RFCs:** hook-mechanism brittleness, skill-discovery
  assumptions, dependency assumptions, measurement rigor, scope
  creep, premise-unverified-by-evidence.
- **PR diffs:** missing E2E coverage, stub routes, secrets in logs,
  backwards-compat cruft, concurrent-write races, error-path handling.
- **Design docs:** user-flow edge cases, accessibility gaps, failure
  modes, mobile viewport, empty / loading / error states.

Read the target's domain (infer from `.claude/rules/` or CLAUDE.md in
the same repo) and add 1-2 domain-specific vectors if relevant.

## Step 3: Compose the adversarial prompt

Template:

```
You are a skeptical reviewer. Your job is to find problems, not
praise. Be a devil's advocate. No prior conversation context — work
only from the artifact and your own knowledge.

Target: <path>
Context note: <optional situational note>

Attack these vectors specifically: <vector list>

For each finding:
- Severity: BLOCKER / MAJOR / MINOR
- The specific fact that makes it wrong or risky
- A concrete edit: file path (or section) + 1-2 sentence revision

Anti-fabrication: if a proposal is fine, say so explicitly. Do not
invent concerns to pad the list.

Hard cap: <word-cap> words.

Read the target in full before responding.
```

## Step 4: Spawn the sub-agent

Invoke `Agent()` with the composed prompt. Use `subagent_type:
"general-purpose"` unless a more specific type fits (e.g.,
`claude-code-guide` for Claude-Code-mechanics questions).

## Step 5: Present findings

Receive the sub-agent's output. Present it verbatim to the user,
preserving severity markers. Do NOT editorialize. If the sub-agent
returned fewer findings than expected, do NOT pad — trust the
"if X is fine, say so" contract.

## Step 6: Offer next steps

Suggest, not prescribe:

- **Apply BLOCKER edits now** — walk through each, apply via Edit tool.
- **Document deferred MAJORs** — add to the artifact's "Accepted risks" section.
- **Re-run on the updated artifact** — only if edits changed the fundamental shape.

## Composability

- `/retrospective` invokes this skill as its review step.
- Can be invoked standalone on any artifact.
- Can be chained: run `plan-review` first (survey), then
  `devil-advocate` (attack). They complement each other.

## When NOT to use

- Docs-only / typo / copy changes.
- Dependency patch bumps.
- When the last devil-advocate run was in the same session on the
  same artifact and nothing material has changed.
- Low-stakes work where Codex or `plan-review` is sufficient.

## See also

- `skill-arsenal/plugins/plan-review/` — survey-style reviewer (5 dimensions).
- `skill-arsenal/plugins/go/` — full pipeline, includes Codex (which is an independent-model adversarial reviewer at the code level).
- `skill-arsenal/plugins/retrospective/` — invokes this skill as step 5.
