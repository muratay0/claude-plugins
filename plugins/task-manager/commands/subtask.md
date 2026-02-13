---
description: Manage subtasks for a parent task
argument-hint: add|list|done|status TASK-ID [args...]
---

# Subtask Management Workflow

Version: 1.0.0
Last Updated: 2025-01-19

## Purpose

Manage subtasks within a parent task. Subtasks allow breaking down large tasks into smaller, trackable units of work.

---

## Input Modes

### Mode 1: Add Subtask
```
/task-manager:subtask add TASK-012 "Implement database schema"
```

### Mode 2: List Subtasks
```
/task-manager:subtask list TASK-012
```

### Mode 3: Mark Done
```
/task-manager:subtask done TASK-012 001
```

### Mode 4: Change Status
```
/task-manager:subtask status TASK-012 001 in_progress
```

---

## Command: add

### Syntax
```
/task-manager:subtask add <TASK-ID> "<title>" [--desc "<description>"]
```

### Execution Steps

#### Step 1: Locate Parent Task

```bash
# Read state.json
Read: ~/task-manager/state.json

# Find task in active tasks
task = state.tasks.active.find(t => t.id === "<TASK-ID>")
TASK_DIR = ~/task-manager/tasks/active/<TASK-ID>-<slug>/
```

#### Step 2: Determine Next Subtask ID

```bash
# List existing subtasks
ls ~/task-manager/tasks/active/<TASK-ID>-<slug>/subtasks/

# Count existing subtasks and increment
# Format: 001, 002, 003, etc.
NEXT_SUBTASK_ID = (count + 1).toString().padStart(3, '0')
```

#### Step 3: Create Subtask File

Use template from `templates/subtask.md`:

```bash
Write: <TASK_DIR>/subtasks/<SUBTASK_ID>-<slug>.md
```

Content:
```markdown
# Subtask <SUBTASK_ID>: <Title>

## Meta
- **Parent:** <TASK-ID>
- **ID:** <SUBTASK_ID>
- **Oluşturulma:** <current date>
- **Durum:** pending
- **Son Güncelleme:** <current date>

## Açıklama
<Description if provided, otherwise "To be defined">

## Checklist
- [ ] Start implementation
- [ ] Test
- [ ] Review

## Notlar
### <current date>
- [CREATED] Subtask oluşturuldu
```

#### Step 4: Update Parent Task

Edit `<TASK_DIR>/task.md`:

1. Update Subtasklar table:
```markdown
## Subtasklar
| ID | Başlık | Durum | Dosya |
|----|--------|-------|-------|
| 001 | <title> | pending | subtasks/001-<slug>.md |
```

2. Add progress note:
```markdown
### <current date>
- [SUBTASK] Subtask <SUBTASK_ID> eklendi: "<title>"
```

#### Step 5: Output Summary

```markdown
## Subtask Created

**Parent Task:** <TASK-ID>
**Subtask ID:** <SUBTASK_ID>
**Title:** <title>
**Location:** <TASK_DIR>/subtasks/<SUBTASK_ID>-<slug>.md

Current subtask count: X
```

---

## Command: list

### Syntax
```
/task-manager:subtask list <TASK-ID>
```

### Execution Steps

#### Step 1: Locate Parent Task

```bash
Read: ~/task-manager/state.json
# Find task location
```

#### Step 2: Read Subtasks

```bash
# List all subtask files
ls <TASK_DIR>/subtasks/*.md

# For each subtask, extract:
# - ID (from filename)
# - Title (from # header)
# - Status (from Durum field)
```

#### Step 3: Output Summary

```markdown
## Subtasks for <TASK-ID>

| ID | Title | Status | Progress |
|----|-------|--------|----------|
| 001 | Database schema | completed | 3/3 |
| 002 | API endpoints | in_progress | 1/4 |
| 003 | Frontend forms | pending | 0/2 |

**Summary:** 1 completed, 1 in progress, 1 pending
```

---

## Command: done

### Syntax
```
/task-manager:subtask done <TASK-ID> <SUBTASK-ID>
```

### Execution Steps

#### Step 1: Locate Subtask

```bash
SUBTASK_FILE = <TASK_DIR>/subtasks/<SUBTASK-ID>-*.md
```

#### Step 2: Update Subtask Status

Edit subtask file:
```markdown
- **Durum:** completed
- **Son Güncelleme:** <current date>
- **Tamamlanma:** <current date>
```

Mark all checklist items as done:
```markdown
- [x] Start implementation
- [x] Test
- [x] Review
```

Add completion note:
```markdown
### <current date>
- [COMPLETED] Subtask tamamlandı
```

#### Step 3: Update Parent Task

Edit `<TASK_DIR>/task.md`:

1. Update Subtasklar table:
```markdown
| 001 | <title> | completed | subtasks/001-<slug>.md |
```

2. Add progress note:
```markdown
### <current date>
- [SUBTASK] Subtask <SUBTASK_ID> tamamlandı
```

#### Step 4: Check Parent Completion

If ALL subtasks are completed:
```markdown
**Note:** All subtasks completed. Consider running `/task-manager:complete <TASK-ID>` to finalize the parent task.
```

#### Step 5: Output Summary

```markdown
## Subtask Completed

**Task:** <TASK-ID>
**Subtask:** <SUBTASK_ID> - <title>
**Completed at:** <current datetime>

Remaining subtasks: X pending, Y in progress
```

---

## Command: status

### Syntax
```
/task-manager:subtask status <TASK-ID> <SUBTASK-ID> <new-status>
```

Valid statuses: `pending`, `in_progress`, `blocked`, `completed`

### Execution Steps

#### Step 1: Locate Subtask

```bash
SUBTASK_FILE = <TASK_DIR>/subtasks/<SUBTASK-ID>-*.md
```

#### Step 2: Update Status

Edit subtask file:
```markdown
- **Durum:** <new-status>
- **Son Güncelleme:** <current date>
```

Add note:
```markdown
### <current date>
- [STATUS] Durum değişti: <old-status> → <new-status>
```

#### Step 3: Update Parent Task

Update Subtasklar table in task.md with new status.

#### Step 4: Output Summary

```markdown
## Subtask Status Updated

**Task:** <TASK-ID>
**Subtask:** <SUBTASK_ID>
**Status:** <old-status> → <new-status>
```

---

## Constants

```
SUBTASK_DIR: <TASK_DIR>/subtasks/
SUBTASK_FORMAT: XXX-<slug>.md (XXX = zero-padded 3 digits)
VALID_STATUSES: pending, in_progress, blocked, completed
```

---

## Error Handling

| Scenario | Action |
|----------|--------|
| Task not found | Show error, list active tasks |
| Subtask not found | Show error, list existing subtasks |
| Invalid status | Show valid status options |
| No arguments | Show usage help |

---

## Usage Examples

### Example 1: Add Multiple Subtasks
```
User: /task-manager:subtask add TASK-012 "Design database schema"
User: /task-manager:subtask add TASK-012 "Implement CRUD operations"
User: /task-manager:subtask add TASK-012 "Write unit tests"
```

### Example 2: Track Progress
```
User: /task-manager:subtask status TASK-012 001 in_progress
User: /task-manager:subtask done TASK-012 001
User: /task-manager:subtask list TASK-012
```

### Example 3: View All Subtasks
```
User: /task-manager:subtask list TASK-012

Output:
## Subtasks for TASK-012

| ID | Title | Status | Progress |
|----|-------|--------|----------|
| 001 | Design database schema | completed | 3/3 |
| 002 | Implement CRUD operations | in_progress | 2/4 |
| 003 | Write unit tests | pending | 0/3 |

**Summary:** 1 completed, 1 in progress, 1 pending
```

---

## Integration with Continue Command

When `/task-manager:continue <TASK-ID>` is run:
- Subtask summary is included in the resume output
- First incomplete subtask is suggested as resume point
- Subtask progress is shown in "Current Progress" section

---

## Best Practices

1. **Granularity**: Keep subtasks small enough to complete in one session
2. **Clear titles**: Use action-oriented titles ("Implement X", "Fix Y", "Add Z")
3. **Sequential work**: Mark subtask as `in_progress` before starting
4. **Complete promptly**: Mark `done` immediately after finishing
5. **Use for blockers**: Use `blocked` status to highlight dependencies
