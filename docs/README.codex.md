# Skill Arsenal for Codex

Guide for using Skill Arsenal with OpenAI Codex via native skill discovery.

## Quick Install

Tell Codex:

```
Clone https://github.com/yanchuk/skill-arsenal to ~/.agents/skill-arsenal, then create directory ~/.agents/skills if it doesn't exist, then symlink ~/.agents/skill-arsenal/skills to ~/.agents/skills/skill-arsenal, then restart.
```

## Manual Installation

### Prerequisites

- OpenAI Codex CLI
- Git

### Steps

1. Clone the repo:
   ```bash
   git clone https://github.com/yanchuk/skill-arsenal.git ~/.agents/skill-arsenal
   ```

2. Create the skills symlink:
   ```bash
   mkdir -p ~/.agents/skills
   ln -s ~/.agents/skill-arsenal/skills ~/.agents/skills/skill-arsenal
   ```

3. Restart Codex.

### Windows

Use a junction instead of a symlink (works without Developer Mode):

```powershell
New-Item -ItemType Directory -Force -Path "$env:USERPROFILE\.agents\skills"
cmd /c mklink /J "$env:USERPROFILE\.agents\skills\skill-arsenal" "$env:USERPROFILE\.agents\skill-arsenal\skills"
```

## How It Works

Codex has native skill discovery — it scans `~/.agents/skills/` at startup, parses SKILL.md frontmatter, and loads skills on demand. Skill Arsenal skills are made visible through a single symlink:

```
~/.agents/skills/skill-arsenal/ → ~/.agents/skill-arsenal/skills/
```

## Available Skills

| Skill | Description |
|-------|-------------|
| **researching-consumer-goods** | Multi-stage consumer product research with global market comparison |
| **writing-well** | Zinsser-based nonfiction writing principles for any text |

## Updating

```bash
cd ~/.agents/skill-arsenal && git pull
```

Skills update instantly through the symlink.

## Uninstalling

```bash
rm ~/.agents/skills/skill-arsenal
```

**Windows (PowerShell):**
```powershell
Remove-Item "$env:USERPROFILE\.agents\skills\skill-arsenal"
```

Optionally delete the clone: `rm -rf ~/.agents/skill-arsenal`

## Troubleshooting

### Skills not showing up

1. Verify the symlink: `ls -la ~/.agents/skills/skill-arsenal`
2. Check skills exist: `ls ~/.agents/skill-arsenal/skills`
3. Restart Codex — skills are discovered at startup

### Windows junction issues

Junctions normally work without special permissions. If creation fails, try running PowerShell as administrator.

## Getting Help

- Report issues: https://github.com/yanchuk/skill-arsenal/issues
- Main documentation: https://github.com/yanchuk/skill-arsenal
