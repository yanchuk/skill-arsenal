# Skill Arsenal for Codex

Guide for using Skill Arsenal with OpenAI Codex via native skill discovery.

## Quick Install

Tell Codex:

```
Install Skill Arsenal for Codex by cloning or updating https://github.com/yanchuk/skill-arsenal in ~/.agents/skill-arsenal, ensuring ~/.agents/skills exists, removing any existing ~/.agents/skills/skill-arsenal entry, recreating ~/.agents/skills/skill-arsenal as a symlink to ~/.agents/skill-arsenal/skills, verifying that ~/.agents/skills/skill-arsenal/writing-well/SKILL.md exists, then restarting Codex.
```

## Manual Installation

### Prerequisites

- OpenAI Codex CLI
- Git

### macOS / Linux

```bash
# 1. Install Skill Arsenal or update an existing clone
if [ -d ~/.agents/skill-arsenal ]; then
  cd ~/.agents/skill-arsenal && git pull
else
  git clone https://github.com/yanchuk/skill-arsenal.git ~/.agents/skill-arsenal
fi

# 2. Create the Codex skills directory
mkdir -p ~/.agents/skills

# 3. Remove any old link or directory at the target path
rm -rf ~/.agents/skills/skill-arsenal

# 4. Create the symlink Codex will scan
ln -s ~/.agents/skill-arsenal/skills ~/.agents/skills/skill-arsenal
```

### Windows

Use a junction instead of a symlink. It works without Developer Mode:

```powershell
if (Test-Path "$env:USERPROFILE\.agents\skill-arsenal") {
  git -C "$env:USERPROFILE\.agents\skill-arsenal" pull
} else {
  git clone https://github.com/yanchuk/skill-arsenal.git "$env:USERPROFILE\.agents\skill-arsenal"
}

New-Item -ItemType Directory -Force -Path "$env:USERPROFILE\.agents\skills" | Out-Null
Remove-Item "$env:USERPROFILE\.agents\skills\skill-arsenal" -Force -Recurse -ErrorAction SilentlyContinue
cmd /c mklink /J "$env:USERPROFILE\.agents\skills\skill-arsenal" "$env:USERPROFILE\.agents\skill-arsenal\skills"
```

### Verify Installation

Use one quick check and one full check:

```bash
ls ~/.agents/skills/skill-arsenal/writing-well/SKILL.md
find -L ~/.agents/skills/skill-arsenal -maxdepth 2 -name SKILL.md | sort
```

The `find -L` form matters. `skills/` is a directory of symlinks, so shallow checks that do not follow symlinks can look broken even when the install is correct.

After verification, restart Codex.

## How It Works

Codex scans `~/.agents/skills/` at startup, reads `SKILL.md` frontmatter, and loads skills on demand. Skill Arsenal becomes visible through one top-level symlink or junction:

```
~/.agents/skills/skill-arsenal/ → ~/.agents/skill-arsenal/skills/
```

Inside the repo, `skills/` is a directory of symlinks into `plugins/.../skills/...`. That keeps one public entry point for Codex while preserving the plugin layout used by the repo.

## Available Skills

| Skill | Description |
|-------|-------------|
| **web-tool-routing** | Shared web tool routing, detection, and fallback chains (infrastructure) |
| **prompt-creator** | Prompt engineering best practices from Anthropic and OpenAI docs (infrastructure) |
| **prompt-74** | High-stakes prompt methodology — PROMPT-74 framework for decisions and deep research (infrastructure) |
| **web-research** | Web research methodology with wave-based execution and structured output (domain) |
| **competitor-research** | Community feedback analysis from Reddit, forums, and review sites (domain) |
| **researching-consumer-goods** | Multi-stage consumer product research with global market comparison (domain) |
| **writing-well** | Zinsser-based nonfiction writing principles for any text (standalone) |
| **plan-review** | Structured technical review of plans and code changes (standalone) |

## Updating

```bash
cd ~/.agents/skill-arsenal && git pull
```

Then restart Codex so it rescans `~/.agents/skills/` and reloads the updated skills.

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

1. Verify the top-level link: `ls -ld ~/.agents/skills/skill-arsenal`
2. Verify one skill resolves through the Codex-visible path: `ls ~/.agents/skills/skill-arsenal/writing-well/SKILL.md`
3. Follow symlinks when checking the full bundle: `find -L ~/.agents/skills/skill-arsenal -maxdepth 2 -name SKILL.md | sort`
4. Restart Codex. Skills are discovered at startup.

### Windows junction issues

Junctions normally work without special permissions. If creation fails, try running PowerShell as administrator.

## Getting Help

- Report issues: https://github.com/yanchuk/skill-arsenal/issues
- Main documentation: https://github.com/yanchuk/skill-arsenal
