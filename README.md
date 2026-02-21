# skill-arsenal

Curated [Agent Skills](https://agentskills.io) for AI coding agents — research, writing, and more. Works with Claude Code, Cursor, Gemini CLI, OpenAI Codex, and any tool supporting the Agent Skills standard.

## Skills

| Skill | Description |
|-------|-------------|
| **researching-consumer-goods** | Multi-stage consumer product research. Gathers requirements, searches global markets, compares prices, and generates structured reports. |
| **writing-well** | Applies Zinsser's nonfiction writing principles to any text — emails, docs, marketing copy, blog posts. Simplicity, clarity, no clutter. |

## Installation

### Claude Code

```bash
# From the plugin marketplace
/plugin marketplace add yanchuk/skill-arsenal
/plugin install researching-consumer-goods
/plugin install writing-well

# Or install a single plugin directly
/plugin install yanchuk/skill-arsenal/researching-consumer-goods
```

### Gemini CLI

```bash
# Install all skills
gemini skills install https://github.com/yanchuk/skill-arsenal.git

# Install a single skill
gemini skills install https://github.com/yanchuk/skill-arsenal.git --path skills/writing-well
```

### Cursor

Open **Cursor Settings → Rules → Add Rule → Remote Rule (GitHub)** and enter:

```
https://github.com/yanchuk/skill-arsenal/tree/main/skills/writing-well
https://github.com/yanchuk/skill-arsenal/tree/main/skills/researching-consumer-goods
```

### OpenAI Codex

```bash
$skill-installer install skills from https://github.com/yanchuk/skill-arsenal
```

### Manual (any agent)

Copy the skill directory into your agent's skills folder:

```bash
# Clone and copy the skill you need
git clone https://github.com/yanchuk/skill-arsenal.git
cp -r skill-arsenal/skills/writing-well ~/.claude/skills/
# Or: ~/.cursor/skills/ | ~/.gemini/skills/ | ~/.agents/skills/
```

## Repo structure

```
skill-arsenal/
├── .claude-plugin/
│   └── marketplace.json        # Claude Code plugin marketplace catalog
├── plugins/                    # Claude Code plugin wrappers
│   ├── researching-consumer-goods/
│   │   ├── .claude-plugin/plugin.json
│   │   └── skills/researching-consumer-goods/
│   └── writing-well/
│       ├── .claude-plugin/plugin.json
│       └── skills/writing-well/
├── skills/                     # Universal entry point (symlinks into plugins/)
│   ├── researching-consumer-goods → ../plugins/.../
│   └── writing-well → ../plugins/.../
└── README.md
```

- **`plugins/`** — Claude Code plugin marketplace format with manifests
- **`skills/`** — Universal [agentskills.io](https://agentskills.io) layout (symlinks). Works with Gemini CLI, Cursor, Codex, and any compliant agent

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
