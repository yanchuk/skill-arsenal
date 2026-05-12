# Skill Arsenal

Agent-agnostic skill collection for research, writing, review, and orchestration.

## Architecture

Four-layer system:

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
├── plan-review      — Technical plan/code review
├── devil-advocate   — Adversarial review
├── agent-task-briefs — Invariant-first worker-agent briefs
└── tasks-for-sonnet — Legacy alias for agent-task-briefs

Orchestration Skills:
├── go
├── quick
├── harness-protocol
└── retrospective
```

See `docs/skill-relations.md` for the full dependency diagram.

## Skill Relationships

- **web-tool-routing** and **prompt-creator** are shared infrastructure — domain skills invoke them at runtime and may add domain-specific overrides
- Domain skills invoke infrastructure skills via the Skill tool (e.g., "Invoke the `web-tool-routing` skill for tool detection")
- Domain overrides are labeled as such (e.g., "Quality-Optimized Override" with explanation of how they differ from defaults)
- External agents (like helper's `web-research-specialist`) can't load skills at runtime — they carry inline overrides + a canonical reference blockquote pointing back to the skill

## How to Create a New Skill

1. Create directory: `plugins/<name>/.claude-plugin/plugin.json` — start at `"version": "1.0.0"`
2. Create directory: `plugins/<name>/.codex-plugin/plugin.json` with the same `name`, `version`, and `description`
3. Create skill: `plugins/<name>/skills/<name>/SKILL.md`
4. Optional references: `plugins/<name>/skills/<name>/references/*.md`
5. Create symlink: `ln -s ../plugins/<name>/skills/<name> skills/<name>`
6. Add entries to `.claude-plugin/marketplace.json` and `.agents/plugins/marketplace.json` with the same `version`
7. Add row to `README.md` skills table
8. Add row to `docs/README.codex.md` and `docs/README.opencode.md`
9. Update `docs/skill-relations.md` diagram if skill has dependencies
10. Validate: `scripts/check-plugin-versions.sh && find -L skills -maxdepth 2 -name SKILL.md | sort`

## How to Update an Existing Skill

Any change to `SKILL.md`, its `references/`, or its frontmatter is a release. Bump the version **before committing** — both files move together:

1. Edit `plugins/<name>/.claude-plugin/plugin.json` and `plugins/<name>/.codex-plugin/plugin.json` → bump `version`
2. Edit `.claude-plugin/marketplace.json` and `.agents/plugins/marketplace.json` → bump the matching plugin entry's `version` to the same number
3. Validate: `./scripts/check-plugin-versions.sh`
4. Commit with a conventional-commit prefix that matches the bump (`feat:` for minor, `fix:` for patch, `feat!:` / `BREAKING CHANGE:` for major)

If you forgot and already committed, follow up with a version-bump commit before pushing — never let `main` diverge from a stale version.

### Mechanical drift check

`scripts/check-plugin-versions.sh` compares every plugin's Claude and Codex manifests against both marketplaces, checks universal skill links, and exits non-zero on drift. Run it manually, in CI, or wire it as a pre-commit hook **once per clone**:

```bash
git config core.hooksPath .githooks
```

After that, every `git commit` runs `.githooks/pre-commit` → the drift check; commits with desynced versions are blocked.

## Versioning (SemVer for skills)

Both `plugins/<name>/.claude-plugin/plugin.json` and `plugins/<name>/.codex-plugin/plugin.json`, plus both marketplace entries, carry a `version`. They MUST move in lockstep — a desync makes the marketplaces lie about what's installed.

| Bump | When | Examples |
|------|------|----------|
| **patch** (`1.0.0` → `1.0.1`) | Typo, wording polish, link fix, formatting cleanup. No behavior change. | Fixing a grammar mistake, reformatting a code block, fixing a broken reference link. |
| **minor** (`1.0.0` → `1.1.0`) | New section, new trigger, new reference file, new stack example. Backward-compatible — old trigger phrases still match, old structure still present. | Adding a new trigger family, splitting a section into `references/`, adding a new "Use when…" trigger phrase, new stack example. |
| **major** (`1.0.0` → `2.0.0`) | Removed triggers, renamed top-level sections that other skills reference, frontmatter shape change, behavior reversal. Anything that breaks an existing caller. | Removing a trigger phrase, renaming `§ Task Template` to `§ Brief`, removing a `references/` file, changing `name:` or required frontmatter keys. |

**The `description` is part of the public API.** Triggers depend on its phrasing — adding a new trigger phrase is minor, removing one is major.

**Skip a bump only for:** files outside the skill's own directory and `marketplace.json` entry (e.g., editing `README.md` rows, `docs/`, this `AGENTS.md`). Those track the catalog, not the skill.

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
# Validate manifest and marketplace structure
scripts/check-plugin-versions.sh

# Check universal skill discovery
find -L skills -maxdepth 2 -name SKILL.md | sort
```
