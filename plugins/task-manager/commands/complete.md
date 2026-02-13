---
description: Complete a task with user approval and archive it
argument-hint: <TASK-ID>
---

# Task Complete Workflow

Version: 1.0.0
Last Updated: 2025-01-18

## Purpose

Mark a task as completed and archive it. **CRITICAL: This command ALWAYS requires explicit user approval before completing.** Tasks cannot be auto-completed by AI.

---

## Critical Rules

1. **NEVER** mark a task complete without explicit user approval
2. **NEVER** skip the approval request
3. **ALWAYS** show task summary before asking for approval
4. **ALWAYS** wait for user response before archiving

---

## Input

```
/task-manager:complete TASK-007
```

---

## Execution Steps

### Step 1: Parse and Locate Task

```bash
TASK_DIR=$(ls -d ~/task-manager/tasks/active/TASK-XXX-* 2>/dev/null | head -1)
```

If not found in active:
```
Error: Task TASK-XXX not found in active tasks.
Check ~/task-manager/tasks/completed/ if already completed.
```

### Step 2: Read Task State

```bash
Read: <TASK_DIR>/task.md
```

Extract:
- Title
- Status
- Plan completion
- Subtasks status
- Outputs list

### Step 3: Validate Completion Readiness

Check:
- [ ] All plan items marked complete
- [ ] All subtasks completed or N/A
- [ ] No in_progress items

If validation fails:
```markdown
## Task Not Ready for Completion

**TASK-XXX** has incomplete items:

### Incomplete Plan Items
- [ ] Item 3: Testing
- [ ] Item 4: Documentation

### Incomplete Subtasks
- 002-implement-feature: in_progress
- 003-write-tests: pending

Please complete these items first, or use `/task-manager:complete TASK-XXX --force` to override.
```

### Step 4: Generate Completion Summary

```markdown
## Task Completion Request: TASK-XXX

**Title:** <title>
**Created:** <creation date>
**Duration:** <days since creation>

### Completion Summary

**Plan Progress:** X/Y items completed
**Subtasks:** A completed, B skipped

### Outputs Generated
- output1.md
- results.json

### Key Accomplishments
<Extract from progress notes>

---

## Approval Required

**Do you approve completing this task?**

This will:
1. Mark task as `completed`
2. Move to `~/task-manager/tasks/completed/`
3. Update state.json

Reply with:
- **yes/approve/tamam** - Complete the task
- **no/cancel** - Keep task active
- **feedback** - Provide additional notes before completing
```

### Step 5: Wait for User Response

**CRITICAL: DO NOT PROCEED WITHOUT EXPLICIT USER APPROVAL**

Valid approval responses:
- "yes", "evet", "approve", "onay", "tamam", "ok", "done"

Invalid/rejection responses:
- "no", "hayır", "cancel", "iptal", "wait"

### Step 6: Process Approval

**If approved:**

#### 6.1 Update task.md

```markdown
- **Durum:** completed
- **Son Güncelleme:** <current datetime>
- **Tamamlanma:** <current datetime>
```

#### 6.2 Add Final Progress Note

```markdown
### <current date>
- Task completed with user approval
- Archived to ~/task-manager/tasks/completed/
```

#### 6.3 Check Completion Checkbox

```markdown
## Kullanıcı Onayı
- [x] Task tamamlandı onayı alındı (<current date>)
```

#### 6.4 Move to Completed

```bash
mv ~/task-manager/tasks/active/TASK-XXX-<slug> ~/task-manager/tasks/completed/
```

#### 6.5 Update State

Following state-management skill protocol:

```bash
# 1. Backup state
Copy: state.json → state.backup.json

# 2. Find and move task from active to completed
task = state.tasks.active.find(t => t.id === "TASK-XXX")
task.status = "completed"
task.updated = "<YYYY-MM-DD>"
task.completedAt = "<YYYY-MM-DD>"

# Remove from active
state.tasks.active = state.tasks.active.filter(t => t.id !== "TASK-XXX")

# Add to completed
state.tasks.completed.push(task)

# Update timestamp
state.lastUpdated = "<ISO-8601 timestamp>"

# 3. Write state
Write: ~/task-manager/state.json

# 4. Verify write
Read: ~/task-manager/state.json
```

### Step 7: Output Confirmation

```markdown
## Task Completed: TASK-XXX

**Title:** <title>
**Completed:** <current datetime>
**Location:** ~/task-manager/tasks/completed/TASK-XXX-<slug>/

### Summary
- Duration: X days
- Outputs: Y files
- Subtasks: Z completed

Task has been archived. View anytime at:
`~/task-manager/tasks/completed/TASK-XXX-<slug>/task.md`
```

---

## Force Completion

With `--force` flag, skip validation:

```
/task-manager:complete TASK-007 --force
```

Still requires user approval, but allows completing tasks with incomplete items.

---

## Cancel Task

To cancel instead of complete:

```
/task-manager:complete TASK-007 --cancel
```

This will:
1. Mark as `cancelled`
2. Move to `~/task-manager/tasks/cancelled/`
3. Record cancellation reason

---

## Error Handling

| Scenario | Action |
|----------|--------|
| Task not found | Show error, list active tasks |
| Task already completed | Show location in completed/ |
| Task already cancelled | Show location in cancelled/ |
| No user response | Remind user approval is required |
| User provides feedback | Record feedback, ask again |

---

## Example Interaction

```
User: /task-manager:complete TASK-010

## Task Completion Request: TASK-010

**Title:** Add Dark Mode Support
**Created:** 2025-01-10
**Duration:** 8 days

### Completion Summary
**Plan Progress:** 4/4 items completed
**Subtasks:** 3 completed, 0 skipped

### Outputs Generated
- dark-mode-styles.css
- theme-toggle.tsx

### Key Accomplishments
- Implemented theme toggle component
- Added CSS variables for theming
- Updated all components to support dark mode

---

## Approval Required

**Do you approve completing this task?**

Reply with: yes/approve/tamam to complete, or no/cancel to keep active.
```

```
User: yes

## Task Completed: TASK-010

**Title:** Add Dark Mode Support
**Completed:** 2025-01-18 14:30:00
**Location:** ~/task-manager/tasks/completed/TASK-010-add-dark-mode-support/

### Summary
- Duration: 8 days
- Outputs: 2 files
- Subtasks: 3 completed

Task has been archived.
```
