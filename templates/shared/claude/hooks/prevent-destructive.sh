#!/usr/bin/env bash
# Hook: Prevent destructive commands in production databases
# Used by Claude Code PreToolUse hook

set -euo pipefail

# Read the tool input from stdin
input=$(cat)

# Extract the command from the JSON input
command=$(echo "$input" | jq -r '.tool_input.command // empty')

# Check for destructive database commands
if echo "$command" | grep -qiE '(DROP\s+(TABLE|DATABASE|INDEX)|TRUNCATE|DELETE\s+FROM\s+\w+\s*$|db:drop|db:reset|db:purge)'; then
  echo "BLOCKED: Destructive database operation detected."
  echo "Please review and run manually if intended."
  exit 2
fi

exit 0
