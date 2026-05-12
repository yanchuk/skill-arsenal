# Skill Arsenal For Codex

Use Skill Arsenal in Codex through direct skill discovery. Codex-native plugin
metadata is included for runtimes that support plugin marketplaces.

## Recommended: Direct Skill Discovery

```bash
if [ -d ~/.agents/skill-arsenal ]; then
  git -C ~/.agents/skill-arsenal pull
else
  git clone https://github.com/yanchuk/skill-arsenal.git ~/.agents/skill-arsenal
fi

mkdir -p ~/.agents/skills
rm -rf ~/.agents/skills/skill-arsenal
ln -s ~/.agents/skill-arsenal/skills ~/.agents/skills/skill-arsenal

find -L ~/.agents/skills/skill-arsenal -maxdepth 2 -name SKILL.md | sort
```

Restart Codex after installing or updating. The `find -L` check matters because
`skills/` is a symlink directory.

## Optional: Codex Plugin Marketplace

```bash
codex plugin marketplace add yanchuk/skill-arsenal --sparse .agents/plugins
```

Upgrade later with:

```bash
codex plugin marketplace upgrade skill-arsenal
```

If plugin marketplace behavior differs in your Codex build, use direct skill
discovery above.

## Windows Fallback

Use a junction instead of a symlink:

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

## Skills

`agent-task-briefs`, `competitor-research`, `devil-advocate`, `go`,
`harness-protocol`, `plan-review`, `prompt-74`, `prompt-creator`, `quick`,
`researching-consumer-goods`, `retrospective`, `tasks-for-sonnet`,
`web-research`, `web-tool-routing`, and `writing-well`.

`tasks-for-sonnet` is a legacy alias. Use `agent-task-briefs` for new work.

## Troubleshooting

```bash
codex plugin marketplace --help
ls -ld ~/.agents/skills/skill-arsenal
find -L ~/.agents/skills/skill-arsenal -maxdepth 2 -name SKILL.md | sort
```

If skills do not appear, restart Codex. Skill discovery happens at startup.
