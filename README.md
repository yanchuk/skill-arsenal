# skill-arsenal

Curated collection of Claude Code skills — research, writing, and more.

## Skills

| Skill | Description |
|-------|-------------|
| **researching-consumer-goods** | Multi-stage consumer product research. Gathers requirements, searches global markets, compares prices, and generates structured reports. |
| **writing-well** | Applies Zinsser's nonfiction writing principles to any text — emails, docs, marketing copy, blog posts. Simplicity, clarity, no clutter. |
| **plan-review** | Structured technical review of plans and code changes. Architecture, code quality, testing, performance, risk — interactive issue-by-issue walkthrough. |
| **competitor-research** | Gathers and analyzes community feedback about competitors from Reddit, forums, and review sites. Structured analysis with sentiment, quotes, and cross-thread synthesis. |

## Installation

### Claude Code (via Plugin Marketplace)

```bash
# Register the marketplace
/plugin marketplace add yanchuk/skill-arsenal

# Install plugins
/plugin install researching-consumer-goods@skill-arsenal
/plugin install writing-well@skill-arsenal
/plugin install plan-review@skill-arsenal
/plugin install competitor-research@skill-arsenal
```

### Cursor

1. Open **Cursor Settings** → **Rules**
2. In **Project Rules**, click **Add Rule** → **Remote Rule (GitHub)**
3. Enter the repository URL:

```
https://github.com/yanchuk/skill-arsenal.git
```

### Codex

```
Fetch and follow instructions from https://raw.githubusercontent.com/yanchuk/skill-arsenal/refs/heads/main/docs/README.codex.md
```

### OpenCode

```
Fetch and follow instructions from https://raw.githubusercontent.com/yanchuk/skill-arsenal/refs/heads/main/docs/README.opencode.md
```

### Manual (any agent)

```bash
git clone https://github.com/yanchuk/skill-arsenal.git
cp -r skill-arsenal/skills/writing-well ~/.claude/skills/
# Or: ~/.cursor/skills/ | ~/.agents/skills/
```

## Repo structure

```
skill-arsenal/
├── .claude-plugin/
│   └── marketplace.json        # Claude Code plugin marketplace catalog
├── docs/                       # Platform-specific install guides
│   ├── README.codex.md
│   └── README.opencode.md
├── plugins/                    # Claude Code plugin wrappers
│   ├── researching-consumer-goods/
│   │   ├── .claude-plugin/plugin.json
│   │   └── skills/researching-consumer-goods/
│   ├── writing-well/
│   │   ├── .claude-plugin/plugin.json
│   │   └── skills/writing-well/
│   ├── plan-review/
│   │   ├── .claude-plugin/plugin.json
│   │   └── skills/plan-review/
│   └── competitor-research/
│       ├── .claude-plugin/plugin.json
│       └── skills/competitor-research/
├── skills/                     # Universal entry point (symlinks into plugins/)
│   ├── researching-consumer-goods → ../plugins/.../
│   ├── writing-well → ../plugins/.../
│   ├── plan-review → ../plugins/.../
│   └── competitor-research → ../plugins/.../
└── README.md
```

- **`plugins/`** — Claude Code plugin marketplace format with manifests
- **`skills/`** — Universal layout (symlinks). Works with Cursor, Codex, and any compliant agent

## Local development

```bash
# Claude Code — test a plugin locally
claude --plugin-dir ./plugins/researching-consumer-goods

# Validate marketplace structure
claude plugin validate .
```

## Contributing

1. Create your plugin directory under `plugins/<name>/`
2. Add `.claude-plugin/plugin.json` with name, description, version, author
3. Add your skill under `plugins/<name>/skills/<skill-name>/SKILL.md`
4. Add a symlink: `ln -s ../plugins/<name>/skills/<skill-name> skills/<skill-name>`
5. Add an entry to `.claude-plugin/marketplace.json`
6. Run `claude plugin validate .` to verify
