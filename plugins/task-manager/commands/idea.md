---
description: Quick capture an idea to backlog
argument-hint: "<title>" [--detailed] [--priority HIGH|MEDIUM|LOW]
---

# Idea Capture Workflow

Version: 1.0.0
Last Updated: 2025-01-18

## Purpose

Quickly capture ideas and future work items to the backlog. Supports two modes:
1. **Quick capture**: Single line added to `ideas.md`
2. **Detailed capture**: Creates a dedicated idea file from template

---

## Input Modes

### Quick Capture (Default)
```
/task-manager:idea "Add dark mode support"
/task-manager:idea "Investigate memory leak in worker service"
```

### Detailed Capture
```
/task-manager:idea "Implement continuous profiling" --detailed
/task-manager:idea "Add webhook retry mechanism" --detailed --priority HIGH
```

### With Priority
```
/task-manager:idea "Fix pagination bug" --priority HIGH
/task-manager:idea "Refactor logging module" --priority LOW
```

---

## Execution Steps

### Step 1: Parse Arguments

From $ARGUMENTS extract:
- Title (required, in quotes)
- `--detailed` flag (optional)
- `--priority HIGH|MEDIUM|LOW` (optional, default: MEDIUM)

### Step 2: Quick Capture Mode

If `--detailed` NOT specified:

#### 2.1 Read Current State

```bash
Read: ~/task-manager/state.json
```

#### 2.2 Add Idea to State

Following state-management skill protocol:

```bash
# 1. Backup state
Copy: state.json → state.backup.json

# 2. Generate idea ID
nextIdeaNum = state.ideas.quick.length + 1
ideaId = "idea-" + padStart(nextIdeaNum, 3, "0")

# 3. Add idea to state
state.ideas.quick.push({
  "id": ideaId,
  "title": "<title>",
  "priority": "<high|medium|low>",
  "added": "<YYYY-MM-DD>",
  "description": "<brief description if provided>"
})

state.lastUpdated = "<ISO-8601 timestamp>"

# 4. Write state
Write: ~/task-manager/state.json
```

#### 2.3 Output Confirmation

```markdown
## Idea Captured

**ID:** <ideaId>
**Title:** <title>
**Priority:** <priority>

Quick capture complete. Use `/task-manager:create --from-idea` when ready to work on it.
```

### Step 3: Detailed Capture Mode

If `--detailed` specified:

#### 3.1 Generate Slug

```bash
SLUG=$(echo "<title>" | tr '[:upper:]' '[:lower:]' | tr ' ' '-' | tr -cd '[:alnum:]-')
```

#### 3.2 Create Idea File

Use template from plugin's `templates/idea.md` and fill variables:

```markdown
# Fikir: <Title>

## Meta
- **Tarih:** <current date>
- **Öncelik:** <HIGH|MEDIUM|LOW>
- **Tahmini Efor:** <ask user or leave blank>

## Açıklama
<Ask user for description or leave placeholder>

## Motivasyon
<Why should this be done?>

## Olası Yaklaşım
<Initial thoughts on implementation>

## Bağımlılıklar
- None identified yet

## Notlar
- Created via /task-manager:idea command

---
**Task'a dönüştürmek için:** `/task-manager:create --from-idea <slug>`
```

Write to: `~/task-manager/tasks/backlog/<slug>.md`

#### 3.3 Update State with Detailed Idea

Following state-management skill protocol:

```bash
# 1. Backup state
Copy: state.json → state.backup.json

# 2. Generate detailed idea ID
nextDetailedNum = state.ideas.detailed.length + 1
ideaId = "idea-d" + padStart(nextDetailedNum, 3, "0")

# 3. Add detailed idea to state
state.ideas.detailed.push({
  "id": ideaId,
  "slug": "<slug>",
  "title": "<title>",
  "priority": "<high|medium|low>",
  "added": "<YYYY-MM-DD>",
  "file": "<slug>.md"
})

state.lastUpdated = "<ISO-8601 timestamp>"

# 4. Write state
Write: ~/task-manager/state.json
```

#### 3.4 Output Confirmation

```markdown
## Detailed Idea Created

**Title:** <title>
**Priority:** <priority>
**Location:** ~/task-manager/tasks/backlog/<slug>.md

Would you like to add more details now?
- Description
- Motivation
- Possible approach
- Dependencies

Or run `/task-manager:create --from-idea <slug>` when ready to start.
```

---

## ideas.md Structure

```markdown
# Ideas & Backlog

Quick ideas and future work items.

## HIGH Priority
- [ ] Critical security fix needed (added: 2025-01-15)
- [ ] Performance optimization for batch jobs (added: 2025-01-10)

## MEDIUM Priority
- [ ] Add dark mode support (added: 2025-01-18)
- [ ] Improve error messages (added: 2025-01-12)

## LOW Priority
- [ ] Refactor legacy code in utils/ (added: 2025-01-05)

## Detailed Ideas
- [Continuous Profiling](continuous-profiling.md) - MEDIUM priority
- [Goroutine Anomaly Alert](goroutine-anomaly-alert.md) - HIGH priority

---
**To convert to task:** `/task-manager:create --from-idea <title-or-slug>`
```

---

## Error Handling

| Scenario | Action |
|----------|--------|
| No title provided | Show usage help |
| ideas.md doesn't exist | Create it with template |
| Duplicate idea title | Warn user, ask to proceed or rename |
| Invalid priority | Default to MEDIUM, warn user |

---

## Examples

### Example 1: Quick Capture
```
User: /task-manager:idea "Add webhook retry with exponential backoff"

## Idea Captured

**Title:** Add webhook retry with exponential backoff
**Priority:** MEDIUM
**Location:** ~/task-manager/tasks/backlog/ideas.md

Quick capture complete.
```

### Example 2: Detailed with Priority
```
User: /task-manager:idea "Implement distributed tracing" --detailed --priority HIGH

## Detailed Idea Created

**Title:** Implement distributed tracing
**Priority:** HIGH
**Location:** ~/task-manager/tasks/backlog/implement-distributed-tracing.md

File created with template. Add details:
- What problem does this solve?
- How might we approach it?
- What dependencies exist?
```

### Example 3: Batch Quick Capture
```
User: /task-manager:idea "Fix null pointer in handler"
User: /task-manager:idea "Add metrics for queue depth"
User: /task-manager:idea "Document API rate limits"

All 3 ideas added to ~/task-manager/tasks/backlog/ideas.md
```

---

## Integration with Task Lifecycle

```
/task-manager:idea "New feature"          → Captured in backlog
         ↓
/task-manager:create --from-idea          → Converts to active task
         ↓
/task-manager:continue TASK-XXX           → Work on task
         ↓
/task-manager:complete TASK-XXX           → Archive completed task
```
