---
description: Manually save checkpoint for current task
argument-hint: ["note"]
---

# Task Checkpoint Workflow

Version: 1.0.0
Last Updated: 2026-01-28

## Purpose

Manually trigger a checkpoint for the current in_progress task. Use this when you want to ensure progress is saved before context loss.

---

## Input

```
/task-manager:checkpoint                    # Basic checkpoint
/task-manager:checkpoint "API analizi"      # Checkpoint with note
```

---

## When to Use

- Before long operations (tests, builds, complex analysis)
- When context feels like it's getting full
- After important discoveries
- Before taking a break
- When you want to ensure progress is persisted

---

## Execution Steps

### Step 1: Find Active Task

```bash
Read: ~/task-manager/state.json

# Find in_progress task
active_task = state.tasks.active.find(t => t.status === "in_progress")

if (!active_task) {
  Output: "No active task (in_progress). Use /task-manager:continue <TASK-ID> first."
  Exit
}
```

### Step 2: Read Current Task State

```bash
TASK_DIR = ~/task-manager/tasks/active/<active_task.id>-<active_task.slug>/
Read: <TASK_DIR>/task.md
```

### Step 3: Generate Checkpoint Entry

Create checkpoint with current timestamp:

```markdown
### YYYY-MM-DD HH:MM (manual checkpoint)
- [CONTEXT] <brief summary of current understanding>
- [COMPLETED] <what has been done since last checkpoint>
- [NEXT] <immediate next action>
```

If user provided a note, include it:
```markdown
### YYYY-MM-DD HH:MM (manual checkpoint)
- [NOTE] <user's note>
- [CONTEXT] <brief summary>
- [COMPLETED] <recent work>
- [NEXT] <next action>
```

### Step 4: Update task.md

```bash
Edit: <TASK_DIR>/task.md
# Append checkpoint entry to "İlerleme Notları" section
# Update "Son Güncelleme" field
```

### Step 5: Reset Tool Counter

```bash
# Read session ID from PPID mapping, then reset session-scoped counter
SESSION_ID=$(cat ~/task-manager/.session-$PPID 2>/dev/null)
if [ -n "$SESSION_ID" ]; then
  echo "0" > ~/task-manager/.tool-count-${SESSION_ID}
fi
```

### Step 6: Update State

```bash
# Backup
Copy: state.json → state.backup.json

# Update timestamp
active_task.updated = "<YYYY-MM-DD>"
state.lastUpdated = "<ISO-8601 timestamp>"

# Write
Write: ~/task-manager/state.json
```

### Step 7: Output Confirmation

```markdown
**Checkpoint saved** @ HH:MM

**Task:** TASK-XXX - <title>
**Updated:** task.md, state.json
**Counter:** Reset to 0

Current state persisted. Safe to continue or take a break.
```

---

## Checkpoint Content Guidelines

When writing the checkpoint entry, include:

### [CONTEXT]
Brief summary of what you currently understand about the task:
- What you're working on
- Key findings so far
- Important state/variables

### [COMPLETED]
What was done since the last checkpoint:
- Files read/analyzed
- Decisions made
- Code written

### [NEXT]
Immediate next action:
- Specific and actionable
- Should be resumable by a fresh context

---

## Error Handling

| Scenario | Action |
|----------|--------|
| No in_progress task | Show message, suggest `/task-manager:continue` |
| task.md not found | Report error, suggest `/task-manager:sync` |
| Write failed | Retry once, report if still fails |

---

## Example

```
User: /task-manager:checkpoint "Kafka consumer analizi tamamlandı"

**Checkpoint saved** @ 14:30

**Task:** TASK-013 - Priority Bazli Vertical Queue
**Updated:** task.md, state.json
**Counter:** Reset to 0

Current state persisted. Safe to continue or take a break.
```

The following entry is added to task.md:

```markdown
### 2026-01-28 14:30 (manual checkpoint)
- [NOTE] Kafka consumer analizi tamamlandı
- [CONTEXT] Vertical queue start/stop mekanizması inceleniyor
- [COMPLETED] Consumer group behavior analiz edildi, partition assignment reviewed
- [NEXT] Priority-based queue ordering implementasyonu planla
```
