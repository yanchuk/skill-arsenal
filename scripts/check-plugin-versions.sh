#!/usr/bin/env bash
# Verify every plugin's version is mirrored in .claude-plugin/marketplace.json.
# Exits 0 on clean, 1 on drift. Safe to run from CI or a git hook.

set -euo pipefail

repo_root="$(git rev-parse --show-toplevel 2>/dev/null || pwd)"
marketplace="$repo_root/.claude-plugin/marketplace.json"

if ! command -v jq >/dev/null 2>&1; then
  echo "check-plugin-versions: jq is required (brew install jq)" >&2
  exit 2
fi

if [[ ! -f "$marketplace" ]]; then
  echo "check-plugin-versions: $marketplace not found" >&2
  exit 2
fi

drift=0

# Plugin manifest → marketplace
while IFS= read -r manifest; do
  name=$(jq -r '.name' "$manifest")
  version=$(jq -r '.version' "$manifest")

  if [[ -z "$name" || "$name" == "null" || -z "$version" || "$version" == "null" ]]; then
    echo "drift: $manifest is missing name or version" >&2
    drift=1
    continue
  fi

  market_version=$(jq -r --arg n "$name" '.plugins[] | select(.name == $n) | .version' "$marketplace")

  if [[ -z "$market_version" || "$market_version" == "null" ]]; then
    echo "drift: $name is in plugins/ but missing from marketplace.json" >&2
    drift=1
  elif [[ "$market_version" != "$version" ]]; then
    echo "drift: $name version mismatch — plugin.json=$version, marketplace.json=$market_version" >&2
    drift=1
  fi
done < <(find "$repo_root/plugins" -mindepth 3 -maxdepth 3 -name plugin.json -type f)

# Marketplace → plugin manifest (catch orphans)
while IFS= read -r name; do
  manifest="$repo_root/plugins/$name/.claude-plugin/plugin.json"
  if [[ ! -f "$manifest" ]]; then
    echo "drift: $name is in marketplace.json but plugins/$name/.claude-plugin/plugin.json is missing" >&2
    drift=1
  fi
done < <(jq -r '.plugins[].name' "$marketplace")

if [[ "$drift" -eq 0 ]]; then
  echo "check-plugin-versions: ok"
fi

exit "$drift"
