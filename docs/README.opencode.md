# Skill Arsenal For OpenCode

Use Skill Arsenal in OpenCode through direct skill discovery.

## Install

```bash
if [ -d ~/.config/opencode/skill-arsenal ]; then
  git -C ~/.config/opencode/skill-arsenal pull
else
  git clone https://github.com/yanchuk/skill-arsenal.git ~/.config/opencode/skill-arsenal
fi

mkdir -p ~/.config/opencode/skills
rm -rf ~/.config/opencode/skills/skill-arsenal
ln -s ~/.config/opencode/skill-arsenal/skills ~/.config/opencode/skills/skill-arsenal
```

Restart OpenCode after installing or updating.

## Windows

```powershell
if (Test-Path "$env:USERPROFILE\.config\opencode\skill-arsenal") {
  git -C "$env:USERPROFILE\.config\opencode\skill-arsenal" pull
} else {
  git clone https://github.com/yanchuk/skill-arsenal.git "$env:USERPROFILE\.config\opencode\skill-arsenal"
}

New-Item -ItemType Directory -Force -Path "$env:USERPROFILE\.config\opencode\skills" | Out-Null
Remove-Item "$env:USERPROFILE\.config\opencode\skills\skill-arsenal" -Force -Recurse -ErrorAction SilentlyContinue
cmd /c mklink /J "$env:USERPROFILE\.config\opencode\skills\skill-arsenal" "$env:USERPROFILE\.config\opencode\skill-arsenal\skills"
```

## Skills

`agent-task-briefs`, `competitor-research`, `devil-advocate`, `go`,
`harness-protocol`, `plan-review`, `prompt-74`, `prompt-creator`, `quick`,
`researching-consumer-goods`, `retrospective`, `tasks-for-sonnet`,
`web-research`, `web-tool-routing`, and `writing-well`.

`tasks-for-sonnet` is a legacy alias. Use `agent-task-briefs` for new work.

## Verify

```bash
ls -ld ~/.config/opencode/skills/skill-arsenal
find -L ~/.config/opencode/skills/skill-arsenal -maxdepth 2 -name SKILL.md | sort
```
