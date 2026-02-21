# Skill Arsenal for OpenCode

Complete guide for using Skill Arsenal with [OpenCode.ai](https://opencode.ai).

## Quick Install

Tell OpenCode:

```
Clone https://github.com/yanchuk/skill-arsenal to ~/.config/opencode/skill-arsenal, then create directory ~/.config/opencode/skills if it doesn't exist, then symlink ~/.config/opencode/skill-arsenal/skills to ~/.config/opencode/skills/skill-arsenal, then restart opencode.
```

## Manual Installation

### Prerequisites

- [OpenCode.ai](https://opencode.ai) installed
- Git

### macOS / Linux

```bash
# 1. Install Skill Arsenal (or update existing)
if [ -d ~/.config/opencode/skill-arsenal ]; then
  cd ~/.config/opencode/skill-arsenal && git pull
else
  git clone https://github.com/yanchuk/skill-arsenal.git ~/.config/opencode/skill-arsenal
fi

# 2. Create skills directory
mkdir -p ~/.config/opencode/skills

# 3. Remove old symlink if it exists
rm -rf ~/.config/opencode/skills/skill-arsenal

# 4. Create symlink
ln -s ~/.config/opencode/skill-arsenal/skills ~/.config/opencode/skills/skill-arsenal

# 5. Restart OpenCode
```

#### Verify Installation

```bash
ls -l ~/.config/opencode/skills/skill-arsenal
```

Should show a symlink pointing to the skill-arsenal skills directory.

### Windows

**Prerequisites:**
- Git installed
- Either **Developer Mode** enabled OR **Administrator privileges**

#### Command Prompt

```cmd
:: 1. Install Skill Arsenal
git clone https://github.com/yanchuk/skill-arsenal.git "%USERPROFILE%\.config\opencode\skill-arsenal"

:: 2. Create skills directory
mkdir "%USERPROFILE%\.config\opencode\skills" 2>nul

:: 3. Remove existing link
rmdir "%USERPROFILE%\.config\opencode\skills\skill-arsenal" 2>nul

:: 4. Create skills junction (works without special privileges)
mklink /J "%USERPROFILE%\.config\opencode\skills\skill-arsenal" "%USERPROFILE%\.config\opencode\skill-arsenal\skills"

:: 5. Restart OpenCode
```

#### PowerShell

```powershell
# 1. Install Skill Arsenal
git clone https://github.com/yanchuk/skill-arsenal.git "$env:USERPROFILE\.config\opencode\skill-arsenal"

# 2. Create skills directory
New-Item -ItemType Directory -Force -Path "$env:USERPROFILE\.config\opencode\skills"

# 3. Remove existing link
Remove-Item "$env:USERPROFILE\.config\opencode\skills\skill-arsenal" -Force -ErrorAction SilentlyContinue

# 4. Create skills junction (works without special privileges)
New-Item -ItemType Junction -Path "$env:USERPROFILE\.config\opencode\skills\skill-arsenal" -Target "$env:USERPROFILE\.config\opencode\skill-arsenal\skills"

# 5. Restart OpenCode
```

#### WSL Users

Use the [macOS / Linux](#macos--linux) instructions instead.

## How It Works

OpenCode discovers skills from `~/.config/opencode/skills/` at startup. Skill Arsenal skills are made visible through a single symlink:

```
~/.config/opencode/skills/skill-arsenal/ → ~/.config/opencode/skill-arsenal/skills/
```

## Available Skills

| Skill | Description |
|-------|-------------|
| **researching-consumer-goods** | Multi-stage consumer product research with global market comparison |
| **writing-well** | Zinsser-based nonfiction writing principles for any text |

## Updating

```bash
cd ~/.config/opencode/skill-arsenal && git pull
```

Restart OpenCode to load the updates.

## Uninstalling

```bash
rm ~/.config/opencode/skills/skill-arsenal
```

**Windows (PowerShell):**
```powershell
Remove-Item "$env:USERPROFILE\.config\opencode\skills\skill-arsenal"
```

Optionally delete the clone: `rm -rf ~/.config/opencode/skill-arsenal`

## Troubleshooting

### Skills not found

1. Verify symlink: `ls -l ~/.config/opencode/skills/skill-arsenal` (should point to skill-arsenal/skills/)
2. Check skills exist: `ls ~/.config/opencode/skill-arsenal/skills/`
3. Restart OpenCode

### Windows junction issues

Junctions normally work without special permissions. If creation fails, try running PowerShell as administrator.

## Getting Help

- Report issues: https://github.com/yanchuk/skill-arsenal/issues
- Main documentation: https://github.com/yanchuk/skill-arsenal
- OpenCode docs: https://opencode.ai/docs/
