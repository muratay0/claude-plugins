#!/bin/bash
# Task Manager Checkpoint Reminder Hook (Multi-Session)
# Tracks tool calls per session and reminds Claude to checkpoint
#
# SESSION OWNERSHIP: Only fires if THIS session has an active task.
# Uses .task-session-{SESSION_ID} file (created by continue command).
# This prevents firing during sprint-runner or other plugin usage.

TASK_MANAGER_DIR="$HOME/task-manager"
CHECKPOINT_INTERVAL=${CHECKPOINT_INTERVAL:-5}

# Read session_id from stdin JSON — no fallback, exit if missing
INPUT=$(cat)
SESSION_ID=$(echo "$INPUT" | jq -r '.session_id // ""' 2>/dev/null)

if [ -z "$SESSION_ID" ]; then
    exit 0
fi

# SESSION OWNERSHIP CHECK: Only fire if THIS session has an active task-manager task
# .task-session-{SESSION_ID} is created by task-manager:continue command
TASK_SESSION_FILE="$TASK_MANAGER_DIR/.task-session-${SESSION_ID}"
if [ ! -f "$TASK_SESSION_FILE" ]; then
    exit 0
fi

# Read this session's active task
CURRENT_TASK=$(cat "$TASK_SESSION_FILE" 2>/dev/null)
if [ -z "$CURRENT_TASK" ]; then
    exit 0
fi

COUNTER_FILE="$TASK_MANAGER_DIR/.tool-count-${SESSION_ID}"

# Ensure directory exists
mkdir -p "$TASK_MANAGER_DIR"

# Write session-to-PPID mapping so Claude can discover its own session ID
echo "$SESSION_ID" > "$TASK_MANAGER_DIR/.session-${PPID}"

# Initialize counter if not exists
if [ ! -f "$COUNTER_FILE" ]; then
    echo "0" > "$COUNTER_FILE"
fi

# Read current count
COUNT=$(cat "$COUNTER_FILE")
COUNT=$((COUNT + 1))
echo "$COUNT" > "$COUNTER_FILE"

# Output reminder when we hit the interval
if [ $((COUNT % CHECKPOINT_INTERVAL)) -eq 0 ]; then
    # Exit code 2 with stderr message feeds back to Claude
    echo "[CHECKPOINT REMINDER] Task: ${CURRENT_TASK}. Update task.md with current progress now. Format: ### YYYY-MM-DD HH:MM - [COMPLETED] ... - [NEXT] ..." >&2
    exit 2
fi

exit 0
