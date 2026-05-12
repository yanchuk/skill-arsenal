#!/usr/bin/env bash
# Verify every plugin's version is mirrored in Claude and Codex manifests.
# Exits 0 on clean, 1 on drift. Safe to run from CI or a git hook.

set -euo pipefail

repo_root="$(git rev-parse --show-toplevel 2>/dev/null || pwd)"
claude_marketplace="$repo_root/.claude-plugin/marketplace.json"
codex_marketplace="$repo_root/.agents/plugins/marketplace.json"

if ! command -v jq >/dev/null 2>&1; then
  echo "check-plugin-versions: jq is required (brew install jq)" >&2
  exit 2
fi

drift=0

check_marketplace() {
  local label="$1"
  local marketplace="$2"
  local manifest_dir="$3"

  if [[ ! -f "$marketplace" ]]; then
    echo "check-plugin-versions: $marketplace not found" >&2
    exit 2
  fi

  while IFS= read -r plugin_dir; do
    local manifest="$plugin_dir/$manifest_dir/plugin.json"
    local plugin_name
    plugin_name="$(basename "$plugin_dir")"

    if [[ ! -f "$manifest" ]]; then
      echo "drift: $label manifest missing for $plugin_name" >&2
      drift=1
      continue
    fi

    local name version description market_version market_description source
    name=$(jq -r '.name' "$manifest")
    version=$(jq -r '.version' "$manifest")
    description=$(jq -r '.description' "$manifest")

    if [[ -z "$name" || "$name" == "null" || -z "$version" || "$version" == "null" || -z "$description" || "$description" == "null" ]]; then
      echo "drift: $manifest is missing name, version, or description" >&2
      drift=1
      continue
    fi

    if [[ "$name" != "$plugin_name" ]]; then
      echo "drift: $manifest name=$name but directory is $plugin_name" >&2
      drift=1
    fi

    market_version=$(jq -r --arg n "$name" '.plugins[] | select(.name == $n) | .version' "$marketplace")
    market_description=$(jq -r --arg n "$name" '.plugins[] | select(.name == $n) | .description' "$marketplace")
    source=$(jq -r --arg n "$name" '.plugins[] | select(.name == $n) | .source' "$marketplace")

    if [[ -z "$market_version" || "$market_version" == "null" ]]; then
      echo "drift: $name is missing from $label marketplace" >&2
      drift=1
    elif [[ "$market_version" != "$version" ]]; then
      echo "drift: $name $label version mismatch — plugin.json=$version, marketplace.json=$market_version" >&2
      drift=1
    fi

    if [[ "$market_description" != "$description" ]]; then
      echo "drift: $name $label description mismatch between plugin.json and marketplace.json" >&2
      drift=1
    fi

    if [[ -z "$source" || "$source" == "null" ]]; then
      echo "drift: $name is missing source in $label marketplace" >&2
      drift=1
    elif [[ "$repo_root/${source#./}" != "$plugin_dir" ]]; then
      echo "drift: $name $label source=$source does not point to $plugin_dir" >&2
      drift=1
    fi

    local skill_file="$plugin_dir/skills/$name/SKILL.md"
    if [[ ! -f "$skill_file" ]]; then
      echo "drift: $name skill entrypoint missing at $skill_file" >&2
      drift=1
    elif ! grep -qE "^name:[[:space:]]*$name$" "$skill_file"; then
      echo "drift: $skill_file frontmatter name does not match $name" >&2
      drift=1
    fi

    local skill_link="$repo_root/skills/$name"
    if [[ ! -e "$skill_link/SKILL.md" ]]; then
      echo "drift: universal skill link missing or broken for $name" >&2
      drift=1
    fi

    if [[ "$manifest_dir" == ".codex-plugin" ]]; then
      local skills_path
      skills_path=$(jq -r '.skills // empty' "$manifest")
      if [[ "$skills_path" != "./skills/" ]]; then
        echo "drift: $manifest must set skills to ./skills/" >&2
        drift=1
      fi
    fi
  done < <(find "$repo_root/plugins" -mindepth 1 -maxdepth 1 -type d | sort)

  while IFS= read -r name; do
    local manifest="$repo_root/plugins/$name/$manifest_dir/plugin.json"
    if [[ ! -f "$manifest" ]]; then
      echo "drift: $name is in $label marketplace but $manifest is missing" >&2
      drift=1
    fi
  done < <(jq -r '.plugins[].name' "$marketplace")
}

check_marketplace "Claude" "$claude_marketplace" ".claude-plugin"
check_marketplace "Codex" "$codex_marketplace" ".codex-plugin"

if [[ -f "$repo_root/plugins/tasks-for-sonnet/skills/tasks-for-sonnet/SKILL.md" ]] \
  && [[ ! -f "$repo_root/plugins/agent-task-briefs/skills/agent-task-briefs/SKILL.md" ]]; then
  echo "drift: tasks-for-sonnet compatibility alias requires agent-task-briefs" >&2
  drift=1
fi

if [[ "$drift" -eq 0 ]]; then
  echo "check-plugin-versions: ok"
fi

exit "$drift"
