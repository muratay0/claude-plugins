# Task Manager Plugin

AI-powered task lifecycle management with session continuity for Claude Code.

## Overview

This plugin provides a complete task management system that:
- Creates and tracks tasks from various sources (manual, Jira, ideas)
- Enables session continuity across Claude Code sessions
- Archives completed tasks with full history
- Supports **multi-session** work (different tasks `in_progress` across different terminals)
- Auto-checkpoints to prevent context loss
- Session-scoped tool counters and lifecycle hooks

## Installation

```bash
# Add marketplace
claude plugin marketplace add etcworld/claude-plugins

# Install plugin
claude plugin install task-manager@etcworld-plugins
```

## Updating

```bash
# Update plugin to latest version
/plugins update task-manager
```

If update doesn't work (cache issue):

```bash
claude plugin marketplace remove etcworld-plugins
claude plugin marketplace add etcworld/claude-plugins
```

## Data Location

All task data is stored in `~/task-manager/` - **not in your project directory**.

This means:
- Tasks are shared across all your projects
- Task data persists independent of any project
- No need to add `tasks/` to `.gitignore`

The plugin automatically creates the directory structure on first use.

## Commands

| Command | Description |
|---------|-------------|
| `/task-manager:create` | Create a new task from title, Jira ticket, or idea |
| `/task-manager:continue` | Resume work on an existing task |
| `/task-manager:pause` | Pause a task and clear session binding |
| `/task-manager:complete` | Complete a task with user approval and archive it |
| `/task-manager:checkpoint` | Manually save checkpoint for current task |
| `/task-manager:subtask` | Manage subtasks (add, list, done, status) |
| `/task-manager:idea` | Quick capture an idea to backlog |
| `/task-manager:list` | List tasks and ideas |
| `/task-manager:sync` | Synchronize state with task folders |
| `/task-manager:protocol` | Reminder of working protocol |

## Skills

The `task-lifecycle` skill automatically activates when you mention:
- "continue", "resume", "devam"
- "what was I working on"
- "last task", "kaldığım yer"

This provides seamless session continuity without explicit commands.

## Multi-Session Support

Work on different tasks from multiple terminals simultaneously:

- **Session-scoped counters** — Each terminal has its own `.tool-count-{session_id}` file
- **No auto-pause** — `/continue TASK-X` in Terminal A does NOT pause Terminal B's task
- **Session tracking** — Each in_progress task records its `sessionId` in state.json
- **Cross-session warnings** — If you try to `/continue` a task active in another session, you'll be warned
- **SessionStart hook** — New sessions automatically detect and display active tasks
- **SessionEnd hook** — Session-specific counter files are cleaned up on exit

### Example: Two Terminals

```
Terminal A: /task-manager:continue TASK-014   → works on HMAC implementation
Terminal B: /task-manager:continue TASK-020   → works on cache fix

state.json:
  TASK-014: { status: "in_progress", sessionId: "abc123" }
  TASK-020: { status: "in_progress", sessionId: "def456" }
```

## Automatic Checkpoint Reminders

The plugin includes hooks that automatically remind Claude to checkpoint:

- **Every 5 tool calls** → Checkpoint reminder injected
- **When task.md edited** → Counter resets (checkpoint detected)
- **Only when active task exists** → No noise when not working on tasks

Hooks are automatically configured via `plugin.json` - no manual setup required.

See `hooks/README.md` for configuration options.

## Directory Structure

All data is stored in `~/task-manager/`:

```
~/task-manager/
├── state.json             # Task state (source of truth, includes sessionId per task)
├── .tool-count-{session}  # Per-session tool call counters (auto-cleaned)
└── tasks/
    ├── active/            # Active tasks
    │   └── TASK-XXX-slug/
    │       ├── task.md    # Task details
    │       ├── subtasks/  # Subtask files
    │       ├── context/   # Context files (session-persistent)
    │       └── outputs/   # Task outputs
    ├── completed/         # Archived completed tasks
    ├── cancelled/         # Cancelled tasks
    ├── backlog/
    │   ├── ideas.md       # Quick ideas list
    │   └── *.md           # Detailed idea files
    └── templates/
        ├── task.md        # Task template
        └── idea.md        # Idea template
```

**Note:** This structure is created automatically when you first use the plugin.

## Usage Examples

### Create a Task

```bash
# From title
/task-manager:create "Implement user authentication"

# From Jira ticket
/task-manager:create --from-jira AT-12345

# From backlog idea
/task-manager:create --from-idea continuous-profiling
```

### Continue Working

```bash
# Resume specific task
/task-manager:continue TASK-007

# List active tasks and choose
/task-manager:continue
```

### Quick Idea Capture

```bash
# Quick capture
/task-manager:idea "Add dark mode support"

# Detailed with priority
/task-manager:idea "Implement distributed tracing" --detailed --priority HIGH
```

### Manage Subtasks

```bash
# Add subtasks to a task
/task-manager:subtask add TASK-007 "Design database schema"
/task-manager:subtask add TASK-007 "Implement CRUD operations"
/task-manager:subtask add TASK-007 "Write unit tests"

# List all subtasks
/task-manager:subtask list TASK-007

# Mark subtask as in progress
/task-manager:subtask status TASK-007 001 in_progress

# Mark subtask as done
/task-manager:subtask done TASK-007 001
```

### Complete a Task

```bash
# Complete with approval
/task-manager:complete TASK-007

# Force complete (with incomplete items)
/task-manager:complete TASK-007 --force
```

### Sync Index

```bash
# Check discrepancies
/task-manager:sync

# Auto-fix discrepancies
/task-manager:sync --fix
```

## Task Lifecycle

```
/task-manager:idea "New feature"          → Captured in backlog
         ↓
/task-manager:create --from-idea          → Converts to active task
         ↓
/task-manager:continue TASK-XXX           → Work on task
         ↓
/task-manager:subtask add TASK-XXX "..."  → Break into subtasks (optional)
         ↓
/task-manager:subtask done TASK-XXX 001   → Track subtask progress
         ↓
/task-manager:complete TASK-XXX           → Archive completed task
```

## Features

### Session Continuity (Context-Safe)

**Problem:** Claude Code's context window can fill up, causing session resets and loss of working memory.

**Solution:** This plugin ensures all progress is persistently saved to disk:

- **Disk is source of truth** - Never rely on conversation history alone
- **Checkpoint after every step** - Progress written to `task.md` immediately
- **Context folder for large data** - Research, decisions, code analysis stored separately
- **Clear position markers** - `[NEXT]`, `[IN_PROGRESS]`, `[COMPLETED]` tags
- **Session recovery** - New session can resume from exact point using disk state

```
~/task-manager/tasks/active/TASK-XXX/
├── task.md           # Current state + position markers
├── context/
│   ├── research.md   # Findings (survives context clear)
│   └── decisions.md  # Decision log (survives context clear)
├── subtasks/         # Individual subtask tracking
└── outputs/          # Deliverables
```

### Subtask Management
- Break large tasks into smaller, trackable units
- Track progress per subtask (pending, in_progress, blocked, completed)
- Auto-updates parent task when subtasks change
- Subtask list shown in `/task-manager:continue` output

### Jira Integration
- Import tasks directly from Jira tickets
- Maintains link to source ticket

### Idea Backlog
- Quick capture mode for fast idea logging
- Detailed mode for well-thought ideas
- Priority levels (HIGH/MEDIUM/LOW)
- Easy conversion to active tasks

### State Management
- Automatic state.json synchronization
- Detects discrepancies between folders and state
- Safe operations (never deletes folders)

## Requirements

- Claude Code CLI
- Optional: Atlassian MCP for Jira integration

## License

MIT

## Author

etcworld (etcworld@gmail.com)
