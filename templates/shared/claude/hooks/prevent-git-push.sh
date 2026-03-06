#!/usr/bin/env bash
# Hook: Prevent git push from Claude Code
# All pushes should be done manually by the developer

set -euo pipefail

input=$(cat)

command=$(echo "$input" | jq -r '.tool_input.command // empty')

if echo "$command" | grep -qE '^git\s+push'; then
  echo "BLOCKED: git push must be done manually."
  exit 2
fi

exit 0
