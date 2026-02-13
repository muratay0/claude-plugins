---
description: Pause an in_progress task
argument-hint: [TASK-ID]
---

# Task Pause Workflow

Version: 1.0.0
Last Updated: 2026-02-13

## Purpose

Manually pause an in_progress task. The `sessionId` and `transcriptPath` are preserved so `/continue` can reference which session last worked on this task.

---

## Input

```
/task-manager:pause TASK-014
/task-manager:pause
```

- With TASK-ID: Pause that specific task
- Without argument: Pause the current session's in_progress task

---

## Execution Steps

### Step 1: Identify Task to Pause

```bash
Read: ~/task-manager/state.json

if (TASK-ID provided) {
  task = state.tasks.active.find(t => t.id === "TASK-XXX")
} else {
  # Find in_progress task for current session
  task = state.tasks.active.find(
    t => t.status === "in_progress" && t.sessionId === CURRENT_SESSION_ID
  )
  # Fallback: any in_progress task if no session match
  if (!task) {
    task = state.tasks.active.find(t => t.status === "in_progress")
  }
}

if (!task) {
  Output: "No in_progress task found to pause."
  Exit
}

if (task.status !== "in_progress") {
  Output: "TASK-XXX is already **{task.status}**, not in_progress."
  Exit
}
```

### Step 2: Update task.md

```bash
TASK_DIR = ~/task-manager/tasks/active/<task.id>-<task.slug>/

Edit: <TASK_DIR>/task.md
Change: "- **Durum:** in_progress" to "- **Durum:** paused"
Update: "- **Son Güncelleme:** <current datetime>"

# Add progress note
Append to İlerleme Notları:
### YYYY-MM-DD HH:MM
- [PAUSED] Task manually paused
```

### Step 3: Update state.json

```bash
# 1. Backup state
Copy: state.json → state.backup.json

# 2. Update task
task.status = "paused"
task.updated = "<YYYY-MM-DD>"
# sessionId and transcriptPath are KEPT — serves as "last worked on by" reference
# /continue uses this to warn: "return to session X with claude --resume"
state.lastUpdated = "<ISO-8601 timestamp>"

# 3. Write state
Write: ~/task-manager/state.json
```

### Step 4: Output Confirmation

```markdown
**Task Paused:** TASK-XXX - <title>

Status: in_progress → paused
Last session: {sessionId} (preserved)

**Next steps:**
- Resume later: `/task-manager:continue TASK-XXX`
- Close this session: `/exit`
- This session stays open until you close it — pausing only changes task status.
```

---

## Error Handling

| Scenario | Action |
|----------|--------|
| Task ID not found | List active tasks, ask user to choose |
| Task not in_progress | Show current status, no change |
| No active tasks | Show message, suggest `/task-manager:list` |
| No arguments, multiple in_progress | List in_progress tasks, ask user to specify |

---

## Examples

### Pause specific task
```
User: /task-manager:pause TASK-014

**Task Paused:** TASK-014 - HMAC Webhook Implementation

Status: in_progress → paused
Last session: a1b2c3 (preserved)

To resume: `/task-manager:continue TASK-014`
To return to original session: `claude --resume`
```

### Pause current session's task
```
User: /task-manager:pause

**Task Paused:** TASK-020 - HMAC Cache Fix Redeploy

Status: in_progress → paused
Last session: d4e5f6 (preserved)

To resume: `/task-manager:continue TASK-020`
```
