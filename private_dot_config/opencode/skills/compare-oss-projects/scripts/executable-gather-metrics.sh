#!/usr/bin/env bash
set -euo pipefail

if [ $# -eq 0 ]; then
  echo "Usage: $0 owner/repo [owner/repo ...]" >&2
  echo "Ex: $0 expressjs/express koajs/koa fastify/fastify" >&2
  exit 1
fi

if ! command -v jq &>/dev/null; then
  echo "jq is required. Install: apt install jq / brew install jq" >&2
  exit 1
fi

fetch_repo() {
  local repo=$1
  if command -v gh &>/dev/null; then
    gh api "repos/$repo" --jq '{
      repo: .full_name,
      stars: .stargazers_count,
      created_at: .created_at,
      language: .language,
      topics: .topics,
      license: (.license.spdx_id // "N/A"),
      pushed_at: .pushed_at,
      forks: .forks_count,
      open_issues: .open_issues_count,
      description: .description
    }' 2>/dev/null
  else
    curl -sf "https://api.github.com/repos/$repo" 2>/dev/null | jq '{
      repo: .full_name,
      stars: .stargazers_count,
      created_at: .created_at,
      language: .language,
      topics: .topics,
      license: (.license.spdx_id // "N/A"),
      pushed_at: .pushed_at,
      forks: .forks_count,
      open_issues: .open_issues_count,
      description: .description
    }' 2>/dev/null
  fi
}

first=true
echo "["
for repo in "$@"; do
  $first || echo ","
  first=false
  data=$(fetch_repo "$repo" || true)
  if [ -z "$data" ] || echo "$data" | jq -e 'has("message")' &>/dev/null; then
    echo "  {\"repo\": \"$repo\", \"error\": \"Not found or API error\"}"
  else
    echo "  $data"
  fi
done
echo "]"