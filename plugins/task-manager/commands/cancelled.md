---
description: Cancel an active task and archive it
argument-hint: <TASK-ID> [reason]
---

# Task Cancel Workflow

Version: 1.0.0
Last Updated: 2026-03-05

## Purpose

Cancel an active task (pending, in_progress, or paused) and archive it to the cancelled folder. Requires user confirmation.

---

## Input

```
/task-manager:cancelled TASK-007
/task-manager:cancelled TASK-007 artik gerekli degil
```

- First argument: TASK-ID (required)
- Remaining text: Cancellation reason (optional, will be prompted if not provided)

---

## Execution Steps

### Step 1: Parse and Locate Task

```bash
Read: ~/task-manager/state.json

task = state.tasks.active.find(t => t.id === "TASK-XXX")

if (!task) {
  # Check completed
  completed = state.tasks.completed.find(t => t.id === "TASK-XXX")
  if (completed) {
    Output: "TASK-XXX is already completed. Location: ~/task-manager/tasks/completed/TASK-XXX-<slug>/"
    Exit
  }
  # Check cancelled
  cancelled = state.tasks.cancelled.find(t => t.id === "TASK-XXX")
  if (cancelled) {
    Output: "TASK-XXX is already cancelled. Location: ~/task-manager/tasks/cancelled/TASK-XXX-<slug>/"
    Exit
  }
  Output: "TASK-XXX not found."
  Exit
}
```

### Step 2: Read Task Details

```bash
TASK_DIR = ~/task-manager/tasks/active/<task.id>-<task.slug>/
Read: <TASK_DIR>/task.md
```

Extract:
- Title
- Status
- Created date
- Progress summary

### Step 3: Show Cancellation Summary and Ask for Confirmation

```markdown
## Task Cancellation Request: TASK-XXX

**Title:** <title>
**Current Status:** <status>
**Created:** <creation date>
**Duration:** <days since creation>

### Progress So Far
<Brief summary from progress notes, or "No progress recorded" if none>

---

## Confirmation Required

**Are you sure you want to cancel this task?**

This will:
1. Mark task as `cancelled`
2. Move to `~/task-manager/tasks/cancelled/`
3. Update state.json

Reply with:
- **yes/evet/tamam** - Cancel the task
- **no/hayir/cancel** - Keep task active
```

If cancellation reason was not provided in the command, also ask:
```markdown
**Cancellation reason** (optional): Please provide a reason, or reply with just "yes" to cancel without a reason.
```

### Step 4: Wait for User Response

**CRITICAL: DO NOT PROCEED WITHOUT EXPLICIT USER CONFIRMATION**

Valid confirmation responses:
- "yes", "evet", "approve", "onay", "tamam", "ok"

Invalid/rejection responses:
- "no", "hayir", "cancel", "iptal", "wait", "vazgec"

### Step 5: Process Cancellation

**If confirmed:**

#### 5.1 Update task.md

```markdown
- **Durum:** cancelled
- **Son Guncelleme:** <current datetime>
- **Iptal Tarihi:** <current datetime>
- **Iptal Nedeni:** <reason or "Belirtilmedi">
```

#### 5.2 Add Final Progress Note

```markdown
### YYYY-MM-DD HH:MM
- [CANCELLED] Task cancelled by user
- Reason: <reason or "Not specified">
- Archived to ~/task-manager/tasks/cancelled/
```

#### 5.3 Move to Cancelled

```bash
# Create cancelled directory if not exists
mkdir -p ~/task-manager/tasks/cancelled/

# Move task
mv ~/task-manager/tasks/active/TASK-XXX-<slug> ~/task-manager/tasks/cancelled/
```

#### 5.4 Update State

```bash
# 1. Backup state
Copy: state.json -> state.backup.json

# 2. Find and move task from active to cancelled
task = state.tasks.active.find(t => t.id === "TASK-XXX")
task.status = "cancelled"
task.updated = "<YYYY-MM-DD>"
task.cancelledAt = "<YYYY-MM-DD>"

# Remove from active
state.tasks.active = state.tasks.active.filter(t => t.id !== "TASK-XXX")

# Add to cancelled
state.tasks.cancelled.push(task)

# Update timestamp
state.lastUpdated = "<ISO-8601 timestamp>"

# 3. Write state
Write: ~/task-manager/state.json

# 4. Verify write
Read: ~/task-manager/state.json

# 5. Remove session ownership file if exists
Bash: rm -f ~/task-manager/.task-session-*TASK-XXX* 2>/dev/null
# Also remove by session ID if task had one
if (task.sessionId) {
  Bash: rm -f ~/task-manager/.task-session-${task.sessionId}
}
```

### Step 6: Output Confirmation

```markdown
## Task Cancelled: TASK-XXX

**Title:** <title>
**Cancelled:** <current datetime>
**Reason:** <reason or "Not specified">
**Location:** ~/task-manager/tasks/cancelled/TASK-XXX-<slug>/

Task has been archived to cancelled. View anytime at:
`~/task-manager/tasks/cancelled/TASK-XXX-<slug>/task.md`
```

---

## Error Handling

| Scenario | Action |
|----------|--------|
| Task not found | Show error, list active tasks |
| Task already completed | Show location in completed/ |
| Task already cancelled | Show location in cancelled/ |
| No user confirmation | Remind user confirmation is required |
| User rejects | Keep task in current state, output "Cancellation aborted" |

---

## Examples

### Cancel with reason
```
User: /task-manager:cancelled TASK-014 oncelik degisti, artik gerekli degil

## Task Cancellation Request: TASK-014

**Title:** HMAC Webhook Implementation
**Current Status:** paused
**Created:** 2025-01-10
**Duration:** 54 days

### Progress So Far
- Initial research completed
- Webhook endpoint structure defined

---

## Confirmation Required

**Are you sure you want to cancel this task?**
**Reason:** oncelik degisti, artik gerekli degil

Reply with: yes/evet/tamam to cancel, or no/hayir to keep active.
```

```
User: evet

## Task Cancelled: TASK-014

**Title:** HMAC Webhook Implementation
**Cancelled:** 2026-03-05 15:00:00
**Reason:** oncelik degisti, artik gerekli degil
**Location:** ~/task-manager/tasks/cancelled/TASK-014-hmac-webhook-implementation/

Task has been archived to cancelled.
```

### Cancel without reason
```
User: /task-manager:cancelled TASK-020

## Task Cancellation Request: TASK-020

**Title:** Cache Fix Redeploy
**Current Status:** pending
**Created:** 2025-02-01
**Duration:** 32 days

### Progress So Far
No progress recorded.

---

## Confirmation Required

**Are you sure you want to cancel this task?**

Reply with: yes/evet/tamam to cancel, or no/hayir to keep active.
You can also provide a reason (optional).
```

```
User: yes

## Task Cancelled: TASK-020

**Title:** Cache Fix Redeploy
**Cancelled:** 2026-03-05 15:00:00
**Reason:** Not specified
**Location:** ~/task-manager/tasks/cancelled/TASK-020-cache-fix-redeploy/

Task has been archived to cancelled.
```
