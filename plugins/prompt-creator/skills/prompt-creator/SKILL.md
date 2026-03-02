---
name: prompt-creator
description: >
  Create effective prompts using proven engineering techniques from
  Anthropic and OpenAI documentation. Use when crafting prompts for
  Claude, ChatGPT, Gemini, or any LLM — system prompts, agent instructions,
  research prompts, or external AI handoff prompts. Also use when other
  skills need to generate "deep research prompts" (Path B external AI
  pattern). Trigger phrases: "create a prompt", "write a prompt for",
  "generate a research prompt", "optimize this prompt", "prompt for ChatGPT".
---

# Prompt Creator

## Why This Skill Exists

Research skills generate external AI prompts (Path B in researching-consumer-goods). Currently that prompt logic is ad-hoc. This skill encodes best practices so any skill can generate high-quality prompts by invoking this shared methodology.

See `references/technique-catalog.md` for the full technique reference with examples and model compatibility notes.

---

## Core Principles (Universal)

These apply to every prompt regardless of target model:

1. **Be clear and direct** — State the desired output explicitly. Don't hint; instruct.
2. **Provide context** — Explain WHY the task matters, not just WHAT to do. Context shapes better responses. *(See: technique-catalog.md → #4 Context Grounding)*
3. **Use examples (3-5 multishot)** — Examples steer format, tone, and reasoning style more effectively than instructions alone. *(See: technique-catalog.md → #2 Few-Shot Examples)*
4. **Structure with markup** — XML tags for Claude, Markdown+XML for OpenAI, Markdown for generic. Structure prevents ambiguity. *(See: technique-catalog.md → #5 XML Tagging)*
5. **Define role/identity upfront** — A clear identity ("You are an expert tax accountant") anchors the model's behavior throughout. *(See: technique-catalog.md → #1 Role Assignment)*
6. **Tell what TO do, not what NOT to do** — "Write concise paragraphs under 3 sentences" beats "Don't write long paragraphs."
7. **Match prompt style to desired output** — A formal prompt yields formal output. A casual prompt yields casual output. The prompt IS the style guide. *(See: technique-catalog.md → #15 Tone/Style Mirroring)*

---

## Structural Template

Order sections from highest to lowest priority. Models weight earlier content more heavily.

### Recommended Section Order

```
1. Identity / Role        — WHO the model is
2. Context                — WHY this task exists, background
3. Instructions           — WHAT to do, step by step
4. Constraints            — Boundaries, limits, format rules
5. Examples               — Input/output pairs (3-5 for format steering)
6. Input Data / Documents — The actual content to process
7. Output Format          — Explicit structure for the response
```

### Claude: XML Tag Pattern

```xml
<identity>
You are an expert [role] specializing in [domain].
</identity>

<context>
[Why this task exists. What the output will be used for.]
</context>

<instructions>
[Step-by-step what to do]
</instructions>

<constraints>
[Boundaries and rules]
</constraints>

<examples>
<example>
<input>[Example input]</input>
<ideal_output>[Example output]</ideal_output>
</example>
</examples>

<document>
[Long documents go here — putting them early improves quality ~30%]
</document>

<output_format>
[Explicit format specification]
</output_format>
```

### OpenAI: Message Role Pattern

```
developer message (highest priority):
  - Identity, instructions, constraints
  - Use `instructions` parameter for high-level directives

user message (medium priority):
  - Context, input data, specific request

assistant message (for few-shot):
  - Example outputs to demonstrate format/style
```

### Generic (Gemini, other): Markdown Pattern

```markdown
# Role
[Identity]

## Context
[Background]

## Instructions
[Steps]

## Examples
### Example 1
**Input:** ...
**Output:** ...

## Output Format
[Structure]
```

---

## Model-Specific Guidance

### Claude

- **XML tags strongly preferred** — `<instructions>`, `<context>`, `<examples>`, `<document>` — Claude parses these as semantic boundaries, not just formatting
- **Long documents at TOP** — Place large context documents early in the prompt (improves quality ~30% vs. placing at end)
- **Adaptive thinking** — For complex reasoning tasks, Claude uses extended thinking automatically; structure prompts to encourage step-by-step reasoning
- **Thinking tags in examples** — Include `<thinking>` blocks in few-shot examples; Claude generalizes the reasoning pattern, not just the output format
- **Multishot with thinking:** When available for your domain, show examples with `<thinking>` blocks demonstrating the reasoning process before the answer *(See: technique-catalog.md → #9 Thinking Blocks in Examples)*
- **Prefill technique** — Start the assistant response to steer output format (e.g., prefill with `{` for JSON, or `<analysis>` for structured output)
- **Chain prompts for complex tasks** — Break multi-step tasks into separate prompts rather than one mega-prompt; pass outputs forward

### OpenAI

- **Message roles matter** — `developer` (high priority), `user` (medium), `assistant` (output examples). Use roles to establish priority hierarchy
- **`instructions` parameter** — For high-level persistent directives that don't change per request
- **Pin to model snapshots in production** — Use dated model IDs (e.g., `gpt-4o-2024-08-06`) for consistent behavior
- **Reasoning models need less hand-holding** — o1/o3 models reason internally; provide the goal and constraints, skip step-by-step breakdowns
- **GPT models need explicit steps** — gpt-4o benefits from numbered step-by-step instructions
- **Structured Outputs** — Use `response_format` with JSON Schema for reliable structured output

### Generic (Gemini, other)

- **Markdown-based structure** — Widest compatibility across models
- **Standard few-shot format** — Input/output pairs with clear delimiters
- **Clear section headers** — Models parse `##` headers as semantic boundaries
- **Avoid model-specific features** — No XML tags, no message roles, no prefill

---

## Anti-Patterns

Avoid these common mistakes (from both Anthropic and OpenAI documentation):

| Anti-Pattern | Problem | Fix |
|-------------|---------|-----|
| **Negative framing** | "Don't use jargon" — models focus on the prohibited thing | "Use plain language a 10th grader would understand" |
| **Overthinking instructions** | 2-page prompt for a simple task wastes context and confuses | Match prompt complexity to task complexity |
| **Over-engineering** | Adding 15 constraints for a creative writing task | Start minimal, add constraints only when output misses the mark |
| **Hard-coding for test cases** | Tuning prompts to ace 3 specific examples | Test against diverse inputs; optimize for the distribution |
| **AI slop aesthetics** | "Certainly!", "Great question!", excessive markdown | Include style constraint: "No preamble. No filler phrases. Direct answers only." |
| **Vague role** | "You are helpful" | "You are a senior backend engineer reviewing Go code for production readiness" |
| **Missing output format** | Hoping the model guesses the right structure | Always specify: JSON schema, markdown template, or explicit example |
| **Prompt-as-essay** | Long prose paragraphs of instructions | Use numbered steps, bullet points, or structured sections |

---

## External AI Prompt Generation (Path B Pattern)

When a skill needs to generate a prompt for the user to paste into an external AI tool (ChatGPT Deep Research, Gemini Deep Research, Claude Extended Thinking), use this template pattern.

This generalizes the handoff prompt pattern from researching-consumer-goods.

### Template Structure

```
## Variables Section
[Table of parameters filled from the invoking skill's context]

## Problem Statement
[Clear, specific description of what to research/analyze/create]

## Requirements
[Numbered list of specific requirements and constraints]

## Sources to Consult
[Authoritative sources, domains, or types of evidence to seek]

## For Each Result, Provide
[Table or list defining the exact fields/columns needed]

## Output Format
[Explicit structure — usually markdown tables per category]

## Quality Constraints
[What makes a good vs. bad result — specificity, verifiability, recency]

## Handoff Instruction
"After receiving results, return here and I'll [what the invoking skill does next]."
```

### Guidelines for Generating Path B Prompts

1. **Fill ALL variables** from the invoking skill's gathered context — never leave placeholders
2. **Be specific about output structure** — the results need to be machine-parseable by the invoking skill's next stage
3. **Include the handoff instruction** — always tell the user to return with results
4. **Scope appropriately** — match items-per-category to the research breadth
5. **Include geo/language context** — external AIs need explicit locale guidance
6. **Specify sources** — domain-specific review sites, authoritative databases
7. **Request URLs** — downstream stages need links to verify, not just recommendations

---

## Prompt Review Checklist

Before delivering a prompt, verify:

- [ ] **Clear identity** — Role is specific, not generic
- [ ] **Context provided** — WHY this task matters is stated
- [ ] **Explicit output format** — Structure is defined, not implied
- [ ] **Examples included** — At least 1 example for format, 3-5 for complex tasks
- [ ] **Positive framing** — Instructions say what TO do
- [ ] **Model-appropriate structure** — XML for Claude, roles for OpenAI, markdown for generic
- [ ] **No unnecessary complexity** — Every instruction earns its place
- [ ] **Tested against edge cases** — Consider: what if input is empty? ambiguous? very long?
- [ ] **Anti-patterns avoided** — No slop aesthetics, no vague roles, no negative framing
- [ ] **Handoff instruction** (if Path B) — User knows what to do with results
