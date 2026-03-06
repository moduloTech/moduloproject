#!/usr/bin/env bash
# Hook: Auto-run RuboCop after editing Ruby files

set -euo pipefail

input=$(cat)

file_path=$(echo "$input" | jq -r '.tool_input.file_path // empty')

if [[ "$file_path" == *.rb ]]; then
  if command -v bundle &>/dev/null && bundle exec rubocop --version &>/dev/null; then
    bundle exec rubocop -a "$file_path" 2>/dev/null || true
  fi
fi

exit 0
