#!/usr/bin/env bash
# Hook: Run Brakeman security check after editing Ruby files

set -euo pipefail

input=$(cat)

file_path=$(echo "$input" | jq -r '.tool_input.file_path // empty')

if [[ "$file_path" == *.rb ]]; then
  if command -v bundle &>/dev/null && bundle list brakeman &>/dev/null; then
    bundle exec brakeman -q --only-files "$file_path" 2>/dev/null || true
  fi
fi

exit 0
