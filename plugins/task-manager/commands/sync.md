---
description: Synchronize state.json with actual task folders
argument-hint: [--dry-run] [--fix] [--rebuild]
---

# Task Sync Workflow

Version: 1.1.0
Last Updated: 2025-01-19

## Purpose

Ensure `~/task-manager/state.json` is synchronized with the actual task folders in `~/task-manager/tasks/active/`, `~/task-manager/tasks/completed/`, and `~/task-manager/tasks/cancelled/`. Detects discrepancies and optionally fixes them.

---

## Input Options

```
/task-manager:sync              # Check and report discrepancies
/task-manager:sync --dry-run    # Same as default, just check
/task-manager:sync --fix        # Automatically fix discrepancies
/task-manager:sync --rebuild    # Full rebuild from disk (use if state.json corrupted)
```

---

## Execution Steps

### Step 1: Scan Actual Folders

```bash
# Get all active tasks
ACTIVE_TASKS=$(ls -d ~/task-manager/tasks/active/TASK-* 2>/dev/null | xargs -n1 basename)

# Get all completed tasks
COMPLETED_TASKS=$(ls -d ~/task-manager/tasks/completed/TASK-* 2>/dev/null | xargs -n1 basename)

# Get all cancelled tasks
CANCELLED_TASKS=$(ls -d ~/task-manager/tasks/cancelled/TASK-* 2>/dev/null | xargs -n1 basename)
```

### Step 2: Parse Current state.json

```bash
Read: ~/task-manager/state.json
```

Extract:
- Tasks in `state.tasks.active`
- Tasks in `state.tasks.completed`
- Tasks in `state.tasks.cancelled`
- Ideas in `state.ideas.quick` and `state.ideas.detailed`

### Step 3: Compare and Detect Discrepancies

| Discrepancy Type | Description |
|------------------|-------------|
| `MISSING_IN_STATE` | Task folder exists but not in state.json |
| `ORPHAN_IN_STATE` | Task in state but folder doesn't exist |
| `WRONG_SECTION` | Task in wrong section (e.g., completed task in active) |
| `STALE_STATUS` | Task status in state doesn't match task.md |
| `ID_MISMATCH` | nextTaskId doesn't match highest existing ID |

### Step 4: Read Task Details

For each detected task folder, read task.md to get:
- Title
- Status (durum)
- Creation date
- Last update

### Step 5: Generate Report

```markdown
## Task Sync Report

**Scan Time:** <current datetime>
**State File:** ~/task-manager/state.json

### Summary
| Category | Count |
|----------|-------|
| Active Tasks (folders) | X |
| Active Tasks (state) | Y |
| Completed Tasks (folders) | A |
| Completed Tasks (state) | B |
| Discrepancies Found | N |

### Discrepancies

#### Missing in State
Tasks that exist in folders but not in state.json:
| Task | Location | Status |
|------|----------|--------|
| TASK-012 | ~/task-manager/tasks/active/TASK-012-new-feature/ | pending |

#### Orphaned in State
Tasks in state but folders don't exist:
| Task | State Section | Expected Location |
|------|---------------|-------------------|
| TASK-999 | tasks.active | ~/task-manager/tasks/active/TASK-999-*/ |

#### Wrong Section
Tasks in wrong state section:
| Task | Current Section | Correct Section |
|------|-----------------|-----------------|
| TASK-008 | tasks.active | tasks.completed |

#### Status Mismatch
Tasks with stale status in state:
| Task | State Status | Actual Status |
|------|--------------|---------------|
| TASK-007 | pending | in_progress |

---

### Recommended Actions

1. Add TASK-012 to state.tasks.active
2. Remove TASK-999 from state (orphan)
3. Move TASK-008 to state.tasks.completed
4. Update TASK-007 status to in_progress

Run `/task-manager:sync --fix` to apply these changes automatically.
```

### Step 6: Apply Fixes (if --fix)

If `--fix` flag provided:

Following state-management skill protocol:

```bash
# 1. Backup state
Copy: state.json → state.backup.json
```

#### 6.1 Add Missing Tasks

For each `MISSING_IN_STATE`:
- Read task.md for details
- Add to appropriate array in state.tasks

#### 6.2 Remove Orphans

For each `ORPHAN_IN_STATE`:
- Remove from state.tasks array
- Note: Does NOT delete folders (safe operation)

#### 6.3 Move Wrong Section

For each `WRONG_SECTION`:
- Remove from current array
- Add to correct array

#### 6.4 Update Status

For each `STALE_STATUS`:
- Update status field in state object

#### 6.5 Fix nextTaskId

If ID_MISMATCH detected:
- Set nextTaskId to highest existing ID + 1

#### 6.6 Write State

```bash
# Update state
state.lastUpdated = "<ISO-8601 timestamp>"
Write: ~/task-manager/state.json
```

### Step 6b: Rebuild Mode (if --rebuild)

If `--rebuild` flag provided (for corrupted state):

```bash
# Create fresh state from disk
state = {
  "version": "1.0.0",
  "lastUpdated": "<now>",
  "nextTaskId": <calculated from highest ID + 1>,
  "tasks": {
    "active": [<scan active/ folder>],
    "completed": [<scan completed/ folder>],
    "cancelled": [<scan cancelled/ folder>]
  },
  "ideas": {
    "quick": [],
    "detailed": [<scan backlog/ folder>]
  }
}

Write: ~/task-manager/state.json
```

### Step 7: Output Result

**If --dry-run or no flag:**
```markdown
## Sync Check Complete

Found X discrepancies. Run `/task-manager:sync --fix` to resolve.
```

**If --fix:**
```markdown
## Sync Complete

**Applied Changes:**
- Added 2 tasks to index
- Removed 1 orphan reference
- Moved 1 task to correct section
- Updated 3 task statuses

Index is now synchronized with task folders.
```

---

## Error Handling

| Scenario | Action |
|----------|--------|
| state.json doesn't exist | Create from scratch with --rebuild |
| state.json corrupted | Try state.backup.json, else --rebuild |
| Task folder has no task.md | Skip, report as warning |
| state.json malformed | Backup and regenerate with --rebuild |
| Permission error | Report and stop |

---

## Example Output

```
User: /task-manager:sync

## Task Sync Report

**Scan Time:** 2025-01-19 10:00:00
**State File:** ~/task-manager/state.json

### Summary
| Category | Count |
|----------|-------|
| Active Tasks (folders) | 6 |
| Active Tasks (state) | 6 |
| Completed Tasks (folders) | 6 |
| Completed Tasks (state) | 6 |
| Discrepancies Found | 0 |

State is synchronized. No action needed.
```
