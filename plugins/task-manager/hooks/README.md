# Task Manager Hooks

Automatic checkpoint reminders and session lifecycle management.

## How It Works

Hooks are **automatically configured** when the plugin is installed via `plugin.json`.

1. **checkpoint-reminder.sh** - Counts tool calls per session, triggers reminder every N calls
2. **checkpoint-reset.sh** - Resets session counter when task.md is edited (checkpoint performed)
3. **session-start.sh** - Detects active tasks on new session, injects resume message
4. **session-end.sh** - Cleans up session-specific counter file

## What Gets Triggered

| Event | Hook | Action |
|-------|------|--------|
| Read, Grep, Glob, Bash, LSP call | checkpoint-reminder.sh | Increment session counter, remind at interval |
| Edit task.md | checkpoint-reset.sh | Reset session counter to 0 |
| Session starts | session-start.sh | Detect active tasks, inject resume message |
| Session ends | session-end.sh | Clean up `.tool-count-{session_id}` file |

## Multi-Session Support

All hooks read `session_id` from stdin JSON. Counters are session-scoped:

- Counter file: `~/task-manager/.tool-count-{session_id}`
- If `session_id` is not available in stdin, hooks exit silently (no fallback)
- Each terminal/session maintains its own independent counter

## How Reminders Work

1. Every tool call (Read, Grep, Glob, Bash, LSP) increments the session counter
2. When counter hits interval (default 5), reminder is injected
3. When task.md is edited (checkpoint), session counter resets to 0
4. Reminders only appear if there's an active task (status: in_progress)

## Example Flow

```
Session abc123:
  Tool 1: Read file.go          # .tool-count-abc123: 1
  Tool 2: Grep pattern          # .tool-count-abc123: 2
  Tool 3: Read another.go       # .tool-count-abc123: 3
  Tool 4: Bash command          # .tool-count-abc123: 4
  Tool 5: Read config.yaml      # .tool-count-abc123: 5 → REMINDER INJECTED

  Claude checkpoints → Edit task.md → .tool-count-abc123 reset to 0

Session def456 (separate terminal):
  Tool 1: Read main.go          # .tool-count-def456: 1  (independent)
  ...
```

## Session Lifecycle

### SessionStart

When a new Claude session starts:
1. Reads `session_id` from stdin
2. Checks state.json for in_progress tasks
3. If active tasks found, injects message listing them with session info
4. Warns if a task is active in another session

**Note:** The session ID is NOT available as an environment variable. PostToolUse hooks write a PPID mapping file (`~/task-manager/.session-{PPID}`) on every tool call. Commands detect the session ID via `cat ~/task-manager/.session-$PPID` — this works because hooks and Claude's Bash tool share the same parent process (Claude CLI).

### SessionEnd

When a Claude session ends:
1. Reads `session_id` from stdin
2. Removes `.tool-count-{session_id}` file (cleanup)

## Configuration

### Checkpoint Interval

Default: Every 5 tool calls

To change, set environment variable before starting Claude:
```bash
export CHECKPOINT_INTERVAL=3
```

Or modify the script directly:
```bash
# In checkpoint-reminder.sh, change:
CHECKPOINT_INTERVAL=${CHECKPOINT_INTERVAL:-5}  # to desired value
```

## Troubleshooting

### Reminders not appearing

1. Check state.json has in_progress task:
   ```bash
   grep in_progress ~/task-manager/state.json
   ```

2. Check session counter file:
   ```bash
   ls ~/task-manager/.tool-count-*
   ```

### Too many/few reminders

Adjust CHECKPOINT_INTERVAL in the script or via environment variable.

### Reset counter manually

```bash
# Find your session counter and reset
echo "0" > ~/task-manager/.tool-count-{your-session-id}
```

### Stale counter files

If session-end hook didn't run (e.g., force quit), counter files may remain:
```bash
# Clean all stale counters
rm ~/task-manager/.tool-count-*
```

## Technical Details

- Counter stored at: `~/task-manager/.tool-count-{session_id}` (per session)
- Hooks defined in: `hooks/hooks.json`
- Scripts location: `hooks/` directory
- Session ID source (hooks): stdin JSON `session_id` field
- Session ID source (commands/prompts): PPID mapping file
  ```bash
  cat ~/task-manager/.session-$PPID 2>/dev/null
  ```
- PPID bridge: hooks and Bash tool share parent (Claude CLI PID), so `.session-{PPID}` is unique per session
