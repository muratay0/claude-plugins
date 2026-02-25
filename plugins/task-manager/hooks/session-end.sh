#!/bin/bash
# Task Manager Session End Hook
# Cleans up session-specific files on session close

TASK_MANAGER_DIR="$HOME/task-manager"

# Read session_id from stdin JSON — no fallback, exit if missing
INPUT=$(cat)
SESSION_ID=$(echo "$INPUT" | jq -r '.session_id // ""' 2>/dev/null)

if [ -z "$SESSION_ID" ]; then
    exit 0
fi

# Clean up session-specific counter file
COUNTER_FILE="$TASK_MANAGER_DIR/.tool-count-${SESSION_ID}"
if [ -f "$COUNTER_FILE" ]; then
    rm -f "$COUNTER_FILE"
fi

# Clean up session task ownership file
TASK_SESSION_FILE="$TASK_MANAGER_DIR/.task-session-${SESSION_ID}"
if [ -f "$TASK_SESSION_FILE" ]; then
    rm -f "$TASK_SESSION_FILE"
fi

# Clean up session-to-PPID mapping file
SESSION_FILE="$TASK_MANAGER_DIR/.session-${PPID}"
if [ -f "$SESSION_FILE" ]; then
    rm -f "$SESSION_FILE"
fi

exit 0
