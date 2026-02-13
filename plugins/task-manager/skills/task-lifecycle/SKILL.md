---
name: task-lifecycle
version: 2.0.0
description: Automatic task context detection, session continuity, and aggressive progress persistence
triggers:
  - "continue"
  - "resume"
  - "what was I working on"
  - "last task"
  - "devam"
  - "kaldığım yer"
---

# Task Lifecycle Skill

Automatically detects task-related context, provides session continuity, and ensures progress is persistently saved to disk.

---

## CRITICAL: Context Overflow Protection

### The Problem
Claude's context window can fill up at ANY moment. When it does:
- All conversation history is LOST
- Any findings not written to disk are LOST
- User must manually restore context

### The Solution: Write-First Protocol
**NEVER hold information only in memory. Write to disk FIRST, then continue.**

```
❌ WRONG: Analyze 5 files → Summarize findings → Write to disk
✅ RIGHT: Analyze file 1 → Write finding → Analyze file 2 → Write finding → ...
```

---

## Aggressive Checkpoint Rules

### Rule 1: Immediate Write (MOST IMPORTANT)

Write to disk IMMEDIATELY after:

| Event | Write To | What to Write |
|-------|----------|---------------|
| Found something interesting | `context/research.md` | The finding + source |
| Made a decision | `context/decisions.md` | Decision + rationale |
| Read important code | `context/code-analysis.md` | Code snippet + analysis |
| Completed any step | `task.md` | Progress note |
| Got API/tool response | `context/` or `outputs/` | The response data |

**No exceptions. No batching. No "I'll write it later".**

### Rule 2: Tool Call Cadence

```
Every 3 tool calls → Update task.md with current status
Every 5 tool calls → Full checkpoint (task.md + all context files)
```

Example:
```
Tool 1: Read file A
Tool 2: Read file B
Tool 3: Read file C
→ CHECKPOINT: Write findings to research.md, update task.md
Tool 4: Grep for pattern
Tool 5: Read file D
→ FULL CHECKPOINT: Update all files
```

### Rule 3: Pre-Operation Save

Before ANY potentially long operation:
- Before running tests → Save current state
- Before complex analysis → Save what you know
- Before making changes → Save the plan
- Before asking user → Save context

### Rule 4: Structured Progress Notes

Every checkpoint in task.md must include:

```markdown
### YYYY-MM-DD HH:MM
- [CONTEXT] What I currently know/understand
- [COMPLETED] What was just done
- [FINDING] Any discoveries (brief, details in context/)
- [NEXT] Immediate next action
- [STATE] Any important state (variables, decisions pending)
```

---

## Write Templates

### research.md - Append Format
```markdown
---
### YYYY-MM-DD HH:MM - <Topic>
**Source:** <file path or URL>
**Finding:** <what was discovered>
**Relevance:** <why this matters for the task>
**Details:**
<detailed notes, code snippets, etc.>
```

### decisions.md - Append Format
```markdown
---
### YYYY-MM-DD HH:MM - <Decision Title>
**Context:** <what led to this decision>
**Options Considered:**
1. Option A - pros/cons
2. Option B - pros/cons
**Decision:** <what was decided>
**Rationale:** <why>
```

### code-analysis.md - Append Format
```markdown
---
### YYYY-MM-DD HH:MM - <File/Component>
**Path:** <file path>
**Purpose:** <what this code does>
**Key Points:**
- Point 1
- Point 2
**Relevant Code:**
\`\`\`<language>
<code snippet>
\`\`\`
**Notes:** <additional observations>
```

---

## Example: Correct Working Flow

### Task: "Analyze authentication system and propose improvements"

```
1. Read task.md to understand current state

2. Start analysis
   → Read auth/login.go
   → IMMEDIATELY write to research.md:
     "### 2025-01-19 14:00 - Login Handler
      Source: auth/login.go
      Finding: Uses bcrypt for password hashing, no rate limiting
      Relevance: Security concern - brute force possible"

3. Continue analysis
   → Read auth/middleware.go
   → IMMEDIATELY write to research.md:
     "### 2025-01-19 14:05 - Auth Middleware
      Source: auth/middleware.go
      Finding: JWT validation present, token expiry = 24h
      Relevance: Token lifetime may be too long"

4. After 3 files analyzed
   → Update task.md:
     "### 2025-01-19 14:10
      - [CONTEXT] Analyzing authentication system
      - [COMPLETED] Reviewed login.go, middleware.go, session.go
      - [FINDING] No rate limiting, long token expiry (details in research.md)
      - [NEXT] Review password reset flow
      - [STATE] 3/7 auth files reviewed"

5. Make a decision
   → IMMEDIATELY write to decisions.md:
     "### 2025-01-19 14:15 - Rate Limiting Approach
      Context: No rate limiting found in login endpoint
      Options: 1) Redis-based, 2) In-memory, 3) Middleware
      Decision: Redis-based rate limiting
      Rationale: Distributed system, need shared state"

6. Continue...
```

---

## Context File Management

### Directory Structure
```
~/task-manager/
├── .tool-count-{session_id}       # Per-session tool call counter
├── state.json                     # Source of truth (with sessionId per task)
└── tasks/active/TASK-XXX-slug/
    ├── task.md                    # Status + progress notes (ALWAYS current)
    ├── context/
    │   ├── research.md            # All findings (append-only)
    │   ├── decisions.md           # All decisions (append-only)
    │   ├── code-analysis.md       # Code snippets + analysis
    │   ├── api-responses.md       # Important API responses
    │   └── scratch.md             # Temporary notes, working memory
    ├── subtasks/
    │   └── XXX-*.md               # Subtask files
    └── outputs/
        └── *                      # Deliverables
```

### File Size Management

If a context file gets large (>500 lines):
1. Create date-based archive: `research-2025-01-19.md`
2. Start fresh `research.md` with link to archive
3. Keep most recent/relevant content in active file

---

## Session Recovery Protocol

### When New Session Starts

1. **Detect active task**: Check `state.json` for in_progress tasks matching current `sessionId`
2. **Cross-session awareness**: If task has a different `sessionId`, warn before resuming
3. **Load context cascade**:
   ```
   task.md → Current status, plan, progress
   context/research.md → Recent findings (last 50 lines)
   context/decisions.md → Recent decisions (last 20 lines)
   context/code-analysis.md → Recent analysis (last 30 lines)
   subtasks/*.md → Subtask statuses
   ```
3. **Find resume point**: Look for `[NEXT]` or `[IN_PROGRESS]` marker
4. **Present summary**: Show user what was loaded
5. **Continue seamlessly**: Pick up exactly where left off

### Recovery Output Format

```markdown
## Session Recovered

**Task:** TASK-XXX - <title>
**Last Active:** YYYY-MM-DD HH:MM

### Context Loaded
- task.md: Status, progress notes
- research.md: X findings loaded
- decisions.md: Y decisions loaded
- code-analysis.md: Z analyses loaded

### Current State
<Last [CONTEXT] entry from task.md>

### Resume Point
<Last [NEXT] entry from task.md>

### Pending Items
<Any [STATE] or incomplete items>

---
Continuing from: <specific action>
```

---

## Checkpoint Triggers

### Automatic (Claude MUST do these)
- After every tool call that returns useful information
- After every decision made
- After completing any step
- Before running tests or builds
- Before any potentially long operation

### User-Requested
- "checkpoint" / "save" / "kaydet"
- "save progress" / "ilerlemeyi kaydet"
- "persist" / "write to disk"

### Time-Based (if detectable)
- Every 5 minutes of active work
- Before responding to user (summarize what was done)

---

## Anti-Patterns to Avoid

### ❌ DON'T: Batch Findings
```
Read 10 files, then write summary
```

### ✅ DO: Incremental Writes
```
Read file → Write finding → Read next file → Write finding
```

### ❌ DON'T: Keep State in Memory
```
"I'll remember that the auth uses JWT"
```

### ✅ DO: Write State to Disk
```
Write to research.md: "Auth system uses JWT with 24h expiry"
```

### ❌ DON'T: Summarize Later
```
"I found several issues, let me summarize at the end"
```

### ✅ DO: Write Each Issue Immediately
```
Found issue 1 → Write → Found issue 2 → Write → ...
```

### ❌ DON'T: Trust Conversation History
```
"As I mentioned earlier, the login handler..."
```

### ✅ DO: Reference Disk
```
"Per research.md entry from 14:00, the login handler..."
```

---

## Emergency Recovery

If context overflows mid-task:

1. User runs `/task-manager:continue TASK-XXX`
2. All context is restored from disk
3. Claude finds `[NEXT]` marker
4. Work continues seamlessly

**This only works if Claude followed the Write-First Protocol!**

---

## Checkpoint Announcement

After every checkpoint, inform user:

```markdown
**Checkpoint** @ HH:MM - Progress saved to disk
- Updated: task.md, research.md
- Current: <brief status>
- Next: <immediate next action>
```

Keep it brief (2-3 lines) but always announce.

---

## Summary: The 5 Commandments

1. **Write First** - Never hold information only in memory
2. **Write Often** - Every 3 tool calls minimum
3. **Write Everything** - Findings, decisions, code, state
4. **Write Immediately** - No batching, no "later"
5. **Announce Writes** - User knows progress is safe
