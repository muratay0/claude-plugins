#!/bin/bash
# Reset checkpoint counter after a checkpoint is performed (Multi-Session)
# This runs when task.md is edited (checkpoint indicator)

# Read input from stdin (JSON with tool_input)
INPUT=$(cat)

# Extract session_id — no fallback, exit if missing
SESSION_ID=$(echo "$INPUT" | jq -r '.session_id // ""' 2>/dev/null)

if [ -z "$SESSION_ID" ]; then
    exit 0
fi

# Write session-to-PPID mapping
TASK_MANAGER_DIR="$HOME/task-manager"
mkdir -p "$TASK_MANAGER_DIR"
echo "$SESSION_ID" > "$TASK_MANAGER_DIR/.session-${PPID}"

# Extract file_path from tool_input
FILE_PATH=$(echo "$INPUT" | jq -r '.tool_input.file_path // ""' 2>/dev/null)

# Only reset counter if editing a task.md file
if [[ "$FILE_PATH" =~ task\.md$ ]]; then
    COUNTER_FILE="$HOME/task-manager/.tool-count-${SESSION_ID}"
    mkdir -p "$(dirname "$COUNTER_FILE")"
    echo "0" > "$COUNTER_FILE"
fi

exit 0
