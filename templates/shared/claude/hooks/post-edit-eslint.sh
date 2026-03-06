#!/usr/bin/env bash
# Hook: Auto-run ESLint after editing JS/Vue/TS files

set -euo pipefail

input=$(cat)

file_path=$(echo "$input" | jq -r '.tool_input.file_path // empty')

if [[ "$file_path" == *.js || "$file_path" == *.vue || "$file_path" == *.ts ]]; then
  if command -v npx &>/dev/null; then
    npx eslint --fix "$file_path" 2>/dev/null || true
  fi
fi

exit 0
