---
name: state-management
version: 1.0.0
description: State file management for task-manager plugin
triggers: []
---

# State Management Skill

Manages the `state.json` file that stores all task and idea metadata.

---

## State File Location

```
~/task-manager/state.json        # Main state file
~/task-manager/state.backup.json # Auto-backup before each write
```

---

## State Schema

```json
{
  "version": "1.0.0",
  "lastUpdated": "ISO-8601 timestamp",
  "nextTaskId": <number>,
  "tasks": {
    "active": [<TaskObject>],
    "completed": [<TaskObject>],
    "cancelled": [<TaskObject>]
  },
  "ideas": {
    "quick": [<QuickIdeaObject>],
    "detailed": [<DetailedIdeaObject>]
  }
}
```

### TaskObject Schema

```json
{
  "id": "TASK-XXX",
  "slug": "task-slug",
  "title": "Task Title",
  "status": "pending|in_progress|paused|waiting_approval|completed|cancelled",
  "created": "YYYY-MM-DD",
  "updated": "YYYY-MM-DD",
  "completedAt": "YYYY-MM-DD (optional)",
  "cancelledAt": "YYYY-MM-DD (optional)",
  "source": "manual|jira:XXX|idea:slug (optional)",
  "sessionId": "string (optional) - active session ID working on this task",
  "transcriptPath": "string (optional) - session transcript file path"
}
```

### Status Definitions

| Status | Description |
|--------|-------------|
| `pending` | Task created but not started |
| `in_progress` | **Currently active** (multiple allowed across different sessions) |
| `paused` | Manually paused by user |
| `waiting_approval` | Waiting for user approval |
| `completed` | Task finished and archived |
| `cancelled` | Task cancelled |

**CONSTRAINT:** Multiple tasks may have `status: "in_progress"` simultaneously, provided each is in a **different session** (unique `sessionId`). A single session should only work on one task at a time.

**Concurrent Access Advisory:** When multiple sessions modify `state.json`, each session must read → backup → modify → write atomically. Session hooks track `sessionId` per task to prevent accidental cross-session interference.

### QuickIdeaObject Schema

```json
{
  "id": "idea-XXX",
  "title": "Idea Title",
  "priority": "high|medium|low",
  "added": "YYYY-MM-DD",
  "description": "Brief description"
}
```

### DetailedIdeaObject Schema

```json
{
  "id": "idea-dXXX",
  "slug": "idea-slug",
  "title": "Idea Title",
  "priority": "high|medium|low",
  "added": "YYYY-MM-DD",
  "file": "filename.md"
}
```

---

## CRITICAL: State Operations Protocol

### Before ANY State Write

1. **Read current state**
   ```bash
   Read: ~/task-manager/state.json
   ```

2. **Create backup**
   ```bash
   Copy: state.json → state.backup.json
   ```

3. **Validate changes** (see Validation Rules below)

4. **Write new state**

5. **Verify write**
   ```bash
   Read: ~/task-manager/state.json
   # Confirm JSON is valid
   ```

### Validation Rules

Before writing, check:
- [ ] JSON is valid (parseable)
- [ ] `version` field exists
- [ ] `nextTaskId` is a positive integer
- [ ] All task IDs are unique
- [ ] All idea IDs are unique
- [ ] All slugs are unique within their category
- [ ] Required fields exist on all objects
- [ ] Status values are valid enum values
- [ ] Dates are valid YYYY-MM-DD format
- [ ] **Each `in_progress` task has a unique `sessionId`** (no two in_progress tasks share the same session)

---

## State Recovery

### If state.json is corrupted

1. **Try backup**
   ```bash
   Copy: state.backup.json → state.json
   ```

2. **If backup also corrupted, rebuild from disk**
   ```bash
   # Scan task directories
   ls ~/task-manager/tasks/active/
   ls ~/task-manager/tasks/completed/
   ls ~/task-manager/tasks/cancelled/

   # Read each task.md and extract metadata
   # Rebuild state.json from extracted data
   ```

3. **Notify user**
   ```markdown
   ⚠️ State file was corrupted and has been rebuilt from task files.
   Please verify with `/task-manager:list --all`
   ```

---

## Command Integration

### Each command MUST:

1. **Read state first**
   ```
   state = Read(~/task-manager/state.json)
   ```

2. **Perform operation**

3. **Update state atomically**
   ```
   state.lastUpdated = now()
   Backup(state.json → state.backup.json)
   Write(state.json)
   ```

### Command → State Mapping

| Command | State Operation |
|---------|-----------------|
| `/task-manager:create` | Add to `tasks.active`, increment `nextTaskId` |
| `/task-manager:continue` | Update task `status`, `updated`, `sessionId` |
| `/task-manager:pause` | Set `status` to `paused`, clear `sessionId` |
| `/task-manager:complete` | Move from `active` to `completed`, set `completedAt` |
| `/task-manager:idea` | Add to `ideas.quick` or `ideas.detailed` |
| `/task-manager:sync` | Rebuild state from disk files |
| `/task-manager:list` | Read-only, no state modification |

---

## ID Generation

### Task ID
```
nextTaskId = state.nextTaskId
newTaskId = "TASK-" + padStart(nextTaskId, 3, "0")
state.nextTaskId = nextTaskId + 1
```

### Quick Idea ID
```
nextIdeaNum = state.ideas.quick.length + 1
newIdeaId = "idea-" + padStart(nextIdeaNum, 3, "0")
```

### Detailed Idea ID
```
nextDetailedNum = state.ideas.detailed.length + 1
newDetailedId = "idea-d" + padStart(nextDetailedNum, 3, "0")
```

---

## Best Practices

1. **Always backup before write** - Prevents data loss
2. **Validate before write** - Prevents corruption
3. **Update lastUpdated** - Tracks modification time
4. **Use atomic operations** - Read → Modify → Write (no partial updates)
5. **Log state changes** - Add to task progress notes

---

## Error Handling

| Error | Action |
|-------|--------|
| state.json not found | Create from template or rebuild from disk |
| JSON parse error | Restore from backup |
| Backup also corrupted | Rebuild from disk, warn user |
| Disk write failed | Retry once, then report error |
| Validation failed | Reject write, report specific error |
