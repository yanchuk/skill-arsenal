---
name: prompt-74
description: >
  High-stakes prompt engineering methodology for real-world decisions
  and deep research. Generates structured, evidence-driven prompts using
  the PROMPT-74 framework: Role + Constraints + Source of Truth →
  Evidence-driven analysis → Actionable deliverable. Use when the user
  needs a thorough, professional-grade prompt for complex decisions,
  deep research, strategy analysis, or any task requiring expert-level
  output with verification. Trigger phrases: "prompt74 this",
  "prompt74 deep research for", "high-stakes prompt", "generate a
  decision prompt", "ownership prompt".
---

# PROMPT-74

High-stakes prompt methodology: (Role + Constraints + Source of Truth)
→ (Evidence-driven analysis) → (Actionable deliverable).

## Why This Skill Exists

Standard prompts produce standard output. For high-stakes decisions
(legal strategy, financial modeling, competitive analysis, immigration
cases), you need prompts that force the model into operator mode — not
assistant mode. PROMPT-74 encodes the methodology that consistently
produces professional-grade output preferred over human expert work.

Inspired by research on GPT-5.2's 74.1% win/tie rate against human
specialists on project-completion benchmarks. Credit: approach developed
by [slash](https://github.com/slash).

## The 10 Rules

### 1. Role + Mindset First
Assign a specific job title AND a mental stance.
Not "be helpful" — instead: "You are an elite skeptical compliance
investigator. Evidence-driven. No hype. No fabrication."

### 2. Tone Constraints
Explicitly ban signal-killing vibes:
- No hustle porn, no fluff, no polite filler, no hallucination
- Demand: concrete, structured, direct

### 3. Source of Truth
Define what facts ARE true in this prompt. Everything else is
unknown until verified. This prevents the model from inventing
convenient context.

### 4. Non-Negotiable Constraints
List hard boundaries: legal, ethical, timeline, budget, must/never.
Prevents the model from drifting into "nice ideas" that violate
your reality.

### 5. Deliverable Format
Tell it exactly what to output: tables, checklists, decision trees,
ranked options, risk matrices. "Make a table with: name / why / fee /
deadline" is a classic PROMPT-74 move.

### 6. Verification + Anti-Fabrication
The model must: prove, cite, flag uncertainty, separate facts from
assumptions. If something can't be verified → say so + offer a
safe workaround.

### 7. Prioritize Speed-to-Action
Ask for next steps executable immediately. Bias toward "what can we
do in 0-30 days?" not "in theory..."

### 8. Risk-First Thinking
Force enumeration of failure modes: legal risk, financial risk,
operational risk, reputational risk. Then propose mitigation plans.

### 9. No Hidden Work
Prevent "I'll do it later" behavior. Require the output now, even
if partial. Partial > promised.

### 10. Iterative Questioning (One at a Time)
When refining requirements, ask one question at a time (up to 10).
Keeps the prompt stable, avoids branching chaos.

## Workflow

### Direct Use ("prompt74 this")
1. User describes the high-stakes task
2. Skill applies iterative questioning (Rule 10) — up to 10 questions,
   one at a time, to gather context
3. Assemble the PROMPT-74 structured prompt using the template below
4. Apply model-specific formatting (invoke `prompt-creator` for
   Claude XML / OpenAI roles / generic markdown guidance)
5. Deliver the prompt directly in conversation for immediate use

### Deep Research Use ("prompt74 deep research for X")
1. Same iterative questioning phase
2. Generate the PROMPT-74 prompt optimized for external AI deep research
   (ChatGPT Deep Research / Gemini Deep Research / Claude Extended Thinking)
3. User pastes into external AI tool
4. User returns with results for further analysis
5. Handoff instruction: "After receiving results, return here and
   I'll analyze, verify, and create an action plan"

## Template

```markdown
## Role & Tone
You are [specific role with years of experience].
Mental stance: [skeptical / evidence-driven / no hype / etc.]
Tone: [concrete, structured, direct. No fluff, no filler, no fabrication.]

## Source of Truth
The following facts are true:
- [fact 1]
- [fact 2]
Everything else is unknown until verified.

## Non-Negotiable Constraints
- MUST: [hard requirements]
- NEVER: [absolute prohibitions]
- Timeline: [deadline]
- Budget: [range]

## Mission
[Clear statement of what decision/research/output is required]

## Output Format
Deliver as:
- [table with columns: X / Y / Z]
- [checklist / decision tree / risk matrix]
- [executive summary]

## Verification Requirements
- Cite sources for every factual claim
- Flag uncertainty explicitly
- Separate facts from assumptions
- If unverifiable, state so + offer safe workaround

## Next Actions
- Step-by-step actions with owners and timeboxes
- Focus on 0-30 day horizon
- Include risk mitigation for each action
```

## Ownership Framing (The 74% Unlock)

For long-term or complex tasks, add ownership framing before the template:

```
This is a long-term task. You own:
- problem framing
- structure
- assumptions
- iteration
- final quality

We will iterate. Maintain internal consistency unless
I explicitly change inputs.
```

This shifts the model from assistant → executor mode.

## Self-Evaluation Step

After generating output, the model should self-critique:

```
Critique this output as if you were a senior reviewer.
Where would this lose credibility?
What would you improve before shipping?
```

## When to Use PROMPT-74 vs. Regular Prompting

| Scenario | Use PROMPT-74 | Use regular prompt |
|----------|:---:|:---:|
| Legal/immigration strategy | ✓ | |
| Financial modeling, cap tables | ✓ | |
| Competitive analysis | ✓ | |
| Hiring/workforce planning | ✓ | |
| Deep research with external AI | ✓ | |
| Quick code fix | | ✓ |
| Simple Q&A | | ✓ |
| Creative writing | | ✓ |
