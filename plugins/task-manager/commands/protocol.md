---
description: Reminder of how to work with task-manager system
argument-hint:
---

# Task Manager Working Protocol

Version: 1.0.0
Last Updated: 2026-01-28

## Purpose

This command reminds Claude how to properly work with the task-manager system. Use this when resuming work after context loss or at the start of a new session.

---

## Multi-Session Task Rule

**Multiple tasks can be `in_progress` across different sessions.** Each session works on one task at a time.

When you `/task-manager:continue TASK-XXX`:
- If THIS session has another in_progress task → that task is set to `paused`
- Tasks in OTHER sessions are NOT affected
- TASK-XXX → set to `in_progress` with current `sessionId`

Status flow:
```
pending → in_progress → completed
            ↓    ↑
          paused (manual only)
```

---

## The 5 Commandments

### 1. Disk is Source of Truth
- **ALWAYS** read task.md before making decisions
- **NEVER** rely on conversation history for task state
- Context can be cleared anytime - disk persists

### 2. Write-First Protocol
- Write important information to disk BEFORE continuing work
- Don't accumulate findings in memory - persist immediately
- If context is lost, written data survives

### 3. Checkpoint Frequently
- After every 3 tool calls, consider checkpointing
- After completing any significant step, checkpoint
- After discovering important information, checkpoint

### 4. Use Context Folder
- Large research findings → `context/research.md`
- Important decisions → `context/decisions.md`
- Code analysis → `context/code-analysis.md`
- Keep task.md concise, details go to context/

### 5. Mark Current Position
- Always maintain clear position markers
- Use `← [IN_PROGRESS]` for current item
- Use `← [NEXT]` for next item to work on

---

## Checkpoint Format

Add to "İlerleme Notları" section in task.md:

```markdown
### YYYY-MM-DD HH:MM
- [COMPLETED] <what was just done>
- [NEXT] <immediate next step>
```

After saving, inform user:
```
**Checkpoint saved** - Progress written to task.md
```

---

## State Management

When task status changes:

```bash
# 1. Backup state
cp ~/task-manager/state.json ~/task-manager/state.backup.json

# 2. Update state.json
- Change status field (pending → in_progress → completed)
- Update "updated" date
- Update "lastUpdated" timestamp

# 3. Verify write
Read state.json to confirm
```

---

## File Locations

```
~/task-manager/
├── state.json                    # Source of truth for all tasks
├── state.backup.json             # Backup before changes
├── .tool-count-{session_id}      # Per-session tool call counter
└── tasks/
    ├── active/TASK-XXX-slug/
    │   ├── task.md               # Main task file
    │   ├── subtasks/             # Subtask files (001-*.md, 002-*.md)
    │   ├── context/              # Research, decisions, analysis
    │   └── outputs/              # Final deliverables
    ├── completed/                # Archived completed tasks
    └── cancelled/                # Cancelled tasks
```

---

## Quick Commands Reference

| Command | Purpose |
|---------|---------|
| `/task-manager:list` | Show all tasks |
| `/task-manager:continue TASK-XXX` | Resume a task |
| `/task-manager:pause [TASK-XXX]` | Pause a task, clear session binding |
| `/task-manager:complete TASK-XXX` | Complete with approval |
| `/task-manager:checkpoint` | **Manual checkpoint** (save now!) |
| `/task-manager:checkpoint "note"` | Checkpoint with note |
| `/task-manager:create "title"` | Create new task |
| `/task-manager:subtask add TASK-XXX "title"` | Add subtask |
| `/task-manager:subtask done TASK-XXX 001` | Mark subtask done |
| `/task-manager:subtask list TASK-XXX` | List subtasks |
| `/task-manager:sync --fix` | Fix state discrepancies |

---

## Anti-Patterns (AVOID)

1. **Memory Accumulation** - Don't collect info across 10+ tool calls without writing
2. **Delayed Writes** - Don't wait until "the end" to write findings
3. **Conversation Trust** - Don't assume previous messages are available
4. **Skipping Checkpoints** - Don't skip saves to "move faster"
5. **Overwriting Context** - Don't replace context files, append or create new ones

---

## When to Use This Command

- Starting a new session on an existing task
- After a long break from a task
- When unsure about the working protocol
- After context window reset
- When onboarding to task-manager system

---

## Manual Checkpoint

Use `/task-manager:checkpoint` when:
- Context feels full
- Before long operations
- After important discoveries
- Before taking a break

```bash
/task-manager:checkpoint                  # Quick save
/task-manager:checkpoint "API tamamlandı" # Save with note
```

---

## Example Session Start

```
User: /task-manager:continue TASK-012

Claude: [Reads task.md, shows current state]

User: /task-manager:protocol

Claude: [Shows this protocol reminder]

User: Let's continue with the next item

Claude: [Follows protocol - reads, works, checkpoints]
```
