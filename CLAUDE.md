# Skill Arsenal

Curated Claude Code skill collection — a Swiss knife for research, writing, and review.

## Architecture

Three-layer system:

```
Infrastructure Skills (invoked by domain skills):
├── web-tool-routing    — HOW to access the web (tool selection, fallback, credits)
├── prompt-creator      — HOW to write prompts (structure, techniques, model-specific)
└── prompt-74           — HOW to structure high-stakes prompts (methodology)

Domain Skills (invoke shared skills + add domain logic):
├── web-research             — General web research methodology
├── competitor-research      — Competitive intelligence from community sources
└── researching-consumer-goods — Consumer product research + price comparison

Standalone Skills (no dependencies):
├── writing-well     — Nonfiction writing principles
└── plan-review      — Technical plan/code review
```

See `docs/skill-relations.md` for the full dependency diagram.

## Skill Relationships

- **web-tool-routing** and **prompt-creator** are shared infrastructure — domain skills invoke them at runtime and may add domain-specific overrides
- Domain skills invoke infrastructure skills via the Skill tool (e.g., "Invoke the `web-tool-routing` skill for tool detection")
- Domain overrides are labeled as such (e.g., "Quality-Optimized Override" with explanation of how they differ from defaults)
- External agents (like helper's `web-research-specialist`) can't load skills at runtime — they carry inline overrides + a canonical reference blockquote pointing back to the skill

## How to Create a New Skill

1. Create directory: `plugins/<name>/.claude-plugin/plugin.json` — start at `"version": "1.0.0"`
2. Create skill: `plugins/<name>/skills/<name>/SKILL.md`
3. Optional references: `plugins/<name>/skills/<name>/references/*.md`
4. Create symlink: `ln -s ../plugins/<name>/skills/<name> skills/<name>`
5. Add entry to `.claude-plugin/marketplace.json` with the same `version`
6. Add row to `README.md` skills table (correct section: infrastructure/domain/standalone)
7. Add row to `docs/README.codex.md` and `docs/README.opencode.md`
8. Update `docs/skill-relations.md` diagram if skill has dependencies
9. Validate: `claude plugin validate .`

## How to Update an Existing Skill

Any change to `SKILL.md`, its `references/`, or its frontmatter is a release. Bump the version **before committing** — both files move together:

1. Edit `plugins/<name>/.claude-plugin/plugin.json` → bump `version`
2. Edit `.claude-plugin/marketplace.json` → bump the matching plugin entry's `version` to the same number
3. Validate: `claude plugin validate .`
4. Commit with a conventional-commit prefix that matches the bump (`feat:` for minor, `fix:` for patch, `feat!:` / `BREAKING CHANGE:` for major)

If you forgot and already committed, follow up with a version-bump commit before pushing — never let `main` diverge from a stale version.

## Versioning (SemVer for skills)

Both `plugins/<name>/.claude-plugin/plugin.json` and the matching entry in `.claude-plugin/marketplace.json` carry a `version`. They MUST move in lockstep — a desync makes the marketplace lie about what's installed.

| Bump | When | Examples |
|------|------|----------|
| **patch** (`1.0.0` → `1.0.1`) | Typo, wording polish, link fix, formatting cleanup. No behavior change. | Fixing a grammar mistake, reformatting a code block, fixing a broken reference link. |
| **minor** (`1.0.0` → `1.1.0`) | New section, new trigger, new reference file, new stack example. Backward-compatible — old trigger phrases still match, old structure still present. | Adding a new trigger family, splitting a section into `references/`, adding a new "Use when…" trigger phrase, new stack example. |
| **major** (`1.0.0` → `2.0.0`) | Removed triggers, renamed top-level sections that other skills reference, frontmatter shape change, behavior reversal. Anything that breaks an existing caller. | Removing a trigger phrase, renaming `§ Task Template` to `§ Brief`, removing a `references/` file, changing `name:` or required frontmatter keys. |

**The `description` is part of the public API.** Triggers depend on its phrasing — adding a new trigger phrase is minor, removing one is major.

**Skip a bump only for:** files outside the skill's own directory and `marketplace.json` entry (e.g., editing `README.md` rows, `docs/`, this `CLAUDE.md`). Those track the catalog, not the skill.

## Conventions

- **Naming:** kebab-case for all skill names
- **Description format:** `>` multiline YAML string, **triggers-first** — start with "Use when…". Description is a dispatch router, not documentation: never list procedural steps, phase names, framework formulas, or implementation internals (those live in the SKILL.md body). Allowed tail: a short principle, a disambiguation ("distinct from X"), or the immediate output — see obra/superpowers skills for canonical examples.
- **Sub-skill invocation:** "Invoke the `<skill-name>` skill for [what it provides]"
- **Domain overrides:** Clearly labeled ("Quality-Optimized Override") with explanation of how they differ from defaults
- **References:** Put large reference material in `references/` subdirectory, not in SKILL.md
- **SKILL.md frontmatter:** `name`, `description` (required), `compatibility` (optional)

## Agent Integration Pattern

Agents can't load skills at runtime. To share skill knowledge with agents:

1. Agent carries **inline overrides** — the specific routing tables or techniques it needs, copied from the skill
2. Agent includes a **canonical reference blockquote** pointing to the skill as source of truth:
   ```
   > **Canonical source:** `web-research` + `web-tool-routing` skills in skill-arsenal.
   ```
3. When the skill updates, agent inline overrides should be reviewed and updated to stay in sync

## Testing

```bash
# Validate marketplace structure
claude plugin validate .

# Test a specific plugin locally
claude --plugin-dir ./plugins/<name>
```
