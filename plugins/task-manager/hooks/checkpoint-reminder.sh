#!/bin/bash
# Task Manager Checkpoint Reminder Hook (Multi-Session)
# Tracks tool calls per session and reminds Claude to checkpoint

TASK_MANAGER_DIR="$HOME/task-manager"
CHECKPOINT_INTERVAL=${CHECKPOINT_INTERVAL:-5}
STATE_FILE="$TASK_MANAGER_DIR/state.json"

# Read session_id from stdin JSON — no fallback, exit if missing
INPUT=$(cat)
SESSION_ID=$(echo "$INPUT" | jq -r '.session_id // ""' 2>/dev/null)

if [ -z "$SESSION_ID" ]; then
    exit 0
fi

COUNTER_FILE="$TASK_MANAGER_DIR/.tool-count-${SESSION_ID}"

# Check if there's an active task
has_active_task() {
    if [ -f "$STATE_FILE" ]; then
        grep -q '"status": "in_progress"' "$STATE_FILE" 2>/dev/null
        return $?
    fi
    return 1
}

# Early exit if no active task - avoid unnecessary disk I/O
if ! has_active_task; then
    exit 0
fi

# Ensure directory exists (only when active task)
mkdir -p "$TASK_MANAGER_DIR"

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
    echo "[CHECKPOINT REMINDER] You've made several tool calls. If working on a task, update task.md with current progress now. Format: ### YYYY-MM-DD HH:MM - [COMPLETED] ... - [NEXT] ..." >&2
    exit 2
fi

exit 0
