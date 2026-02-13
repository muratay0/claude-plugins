#!/usr/bin/env bash
set -euo pipefail

# Auto-approve Write/Edit/Bash operations targeting task-manager directory.
# This bypasses Claude Code's broken ** glob matching for Write/Edit tools.

TASK_MANAGER_DIR="$HOME/.claude/task-manager"

input=$(cat)

tool_name=$(echo "$input" | jq -r '.tool_name // ""')
file_path=$(echo "$input" | jq -r '.tool_input.file_path // ""')
command=$(echo "$input" | jq -r '.tool_input.command // ""')

approve() {
  echo "{\"hookSpecificOutput\": {\"permissionDecision\": \"allow\", \"permissionDecisionReason\": \"$1\"}}"
  exit 0
}

case "$tool_name" in
  Write|Edit)
    if [[ "$file_path" == "$TASK_MANAGER_DIR"/* ]]; then
      approve "task-manager path: $file_path"
    fi
    ;;
  Bash)
    # mkdir for task directories
    if [[ "$command" == mkdir* && "$command" == *"$TASK_MANAGER_DIR"* ]]; then
      approve "mkdir in task-manager: $command"
    fi
    # cp for state.json backup
    if [[ "$command" == cp* && "$command" == *"$TASK_MANAGER_DIR/state.json"* ]]; then
      approve "state.json backup: $command"
    fi
    ;;
esac

# No match — fall through to normal permission handling
exit 0
