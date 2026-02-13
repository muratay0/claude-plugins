#!/bin/bash
# Task Manager Session Start Hook
# Detects active tasks and injects resume message into new sessions

TASK_MANAGER_DIR="$HOME/task-manager"
STATE_FILE="$TASK_MANAGER_DIR/state.json"

# Read session_id from stdin JSON — no fallback, exit if missing
INPUT=$(cat)
SESSION_ID=$(echo "$INPUT" | jq -r '.session_id // ""' 2>/dev/null)

if [ -z "$SESSION_ID" ]; then
    exit 0
fi

# Check if state.json exists
if [ ! -f "$STATE_FILE" ]; then
    exit 0
fi

# Find in_progress tasks and their sessionId info
ACTIVE_TASKS=$(jq -r '
    .tasks.active[]
    | select(.status == "in_progress")
    | "\(.id) | \(.title) | \(.sessionId // "none")"
' "$STATE_FILE" 2>/dev/null)

if [ -z "$ACTIVE_TASKS" ]; then
    exit 0
fi

# Inject message to Claude about active tasks
{
    echo "[SESSION START] Active tasks detected (this session: ${SESSION_ID}):"
    echo "$ACTIVE_TASKS" | while IFS='|' read -r task_id title session_id; do
        task_id=$(echo "$task_id" | xargs)
        title=$(echo "$title" | xargs)
        session_id=$(echo "$session_id" | xargs)
        if [ "$session_id" != "none" ] && [ "$session_id" != "$SESSION_ID" ]; then
            echo "  - ${task_id}: ${title} (active in session: ${session_id})"
        else
            echo "  - ${task_id}: ${title}"
        fi
    done
    echo "Use /task-manager:continue <TASK-ID> to resume a task."
} >&2

exit 2
