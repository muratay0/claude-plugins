---
description: List tasks and ideas
argument-hint: [--active] [--completed] [--ideas] [--all]
---

# Task List Workflow

Version: 1.0.0
Last Updated: 2025-01-19

## Purpose

Display tasks and ideas from the task management system. Supports filtering by status.

---

## Input Options

```
/task-manager:list              # Default: active tasks + recent ideas
/task-manager:list --active     # Only active tasks
/task-manager:list --completed  # Only completed tasks
/task-manager:list --ideas      # Only backlog ideas
/task-manager:list --all        # Everything
```

---

## Execution Steps

### Step 1: Parse Arguments

From $ARGUMENTS extract filter:
- `--active` → Show active tasks only
- `--completed` → Show completed tasks only
- `--ideas` → Show backlog ideas only
- `--all` → Show everything
- No argument → Show active tasks + ideas summary

### Step 2: Read State

All data comes from state.json for fast retrieval:

```bash
Read: ~/task-manager/state.json
```

### Step 3: Extract Task Info from State

From `state.tasks.active`:
- ID, slug, title, status, created, updated

From `state.tasks.completed`:
- ID, slug, title, status, completedAt

From `state.tasks.cancelled`:
- ID, slug, title, cancelledAt

### Step 4: Extract Ideas Info from State

From `state.ideas.quick`:
- ID, title, priority, added, description

From `state.ideas.detailed`:
- ID, slug, title, priority, added, file

### Step 5: Output Results

#### Default Output (no arguments)

```markdown
## Task Manager Overview

### Active Tasks (X)
| ID | Title | Status | Last Updated |
|----|-------|--------|--------------|
| TASK-007 | Reverse Identity Catchup | in_progress | 2025-01-15 |
| TASK-011 | Integration Test Cleanup | in_progress | 2025-01-05 |
| ... | ... | ... | ... |

### Ideas Summary
- **HIGH Priority:** X items
- **MEDIUM Priority:** Y items
- **LOW Priority:** Z items
- **Detailed Ideas:** N files

Run `/task-manager:list --ideas` for full idea list.
```

#### Active Only (--active)

```markdown
## Active Tasks

| ID | Title | Status | Session | Last Updated |
|----|-------|--------|---------|--------------|
| TASK-006 | Reverse Identity Bulk Migration | **in_progress** | a1b2.. | 2024-12-10 |
| TASK-007 | Reverse Identity Catchup | **in_progress** | c3d4.. | 2025-01-15 |
| TASK-001 | Victoria Prometheus Migration | pending | - | 2024-12-04 |
| ... | ... | ... | ... | ... |

Total: X active tasks
- In Progress: N (across M sessions)
- Paused: Y
- Pending: Z
```

#### Completed Only (--completed)

```markdown
## Completed Tasks

| ID | Title | Completed |
|----|-------|-----------|
| TASK-010 | Identity A-B Comparison Test | 2025-01-05 |
| TASK-009 | Tilt Sürüm Güncellemesi | 2025-01-05 |
| ... | ... | ... |

Total: X completed tasks
```

#### Ideas Only (--ideas)

```markdown
## Backlog Ideas

### HIGH Priority
- [ ] Critical security fix needed (added: 2025-01-15)

### MEDIUM Priority
- [ ] Add dark mode support (added: 2025-01-18)

### LOW Priority
- [ ] Refactor legacy code (added: 2025-01-05)

### Detailed Ideas
| Title | Priority | File |
|-------|----------|------|
| Continuous Profiling | MEDIUM | continuous-profiling.md |
| Goroutine Anomaly Alert | HIGH | goroutine-anomaly-alert.md |

Total: X quick ideas, Y detailed ideas
```

#### All (--all)

Combines all sections above.

---

## Error Handling

| Scenario | Action |
|----------|--------|
| No tasks found | Show "No tasks yet. Create one with /task-manager:create" |
| No ideas found | Show "No ideas yet. Add one with /task-manager:idea" |
| Data directory missing | Initialize structure and show empty state |

---

## Examples

### Example 1: Quick Overview
```
User: /task-manager:list

## Task Manager Overview

### Active Tasks (7)
| ID | Title | Status | Last Updated |
|----|-------|--------|--------------|
| TASK-007 | Reverse Identity Catchup | in_progress | 2025-01-15 |
| TASK-011 | Integration Test Cleanup | in_progress | 2025-01-05 |
| TASK-006 | Reverse Identity Bulk Migration | in_progress | 2024-12-10 |
| TASK-001 | Victoria Prometheus Migration | pending | 2024-12-04 |
| ... | ... | ... | ... |

### Ideas Summary
- **HIGH Priority:** 2 items
- **MEDIUM Priority:** 3 items
- **Detailed Ideas:** 5 files
```

### Example 2: Ideas Only
```
User: /task-manager:list --ideas

## Backlog Ideas

### Detailed Ideas
| Title | Priority | File |
|-------|----------|------|
| Continuous Profiling | MEDIUM | continuous-profiling.md |
| Go Runtime Monitoring | MEDIUM | go-runtime-monitoring.md |
| Goroutine Anomaly Alert | HIGH | goroutine-anomaly-alert.md |

Total: 5 detailed ideas

To convert to task: /task-manager:create --from-idea <slug>
```
