---
description: "Convert PRDs to prd.json format for the Ralph autonomous agent system. Use when you have an existing PRD and need to convert it to Ralph's JSON format."
---

# Ralph PRD Converter

Converts existing PRDs to the prd.json format that Ralph uses for autonomous execution.

**Note:** For new projects, use `/ralph-prd` instead - it generates both PRD.md and prd.json with full test requirements. This converter is for existing/external PRDs.

---

## The Job

Take a PRD (markdown file or text) and convert it to `.ralph/prd.json`.

**Important:** When converting, ensure every story has test requirements. If the source PRD lacks them, add appropriate test requirements based on the story type.

---

## Output Format

```json
{
  "project": "[Project Name]",
  "description": "[Feature description from PRD title/intro]",
  "userStories": [
    {
      "id": "US-001",
      "title": "[Story title]",
      "description": "As a [user], I want [feature] so that [benefit]",
      "acceptanceCriteria": [
        "Criterion 1",
        "Criterion 2",
        "Unit test: specific test case",
        "Integration test: specific test case",
        "Typecheck passes",
        "All tests pass"
      ],
      "passes": false,
      "notes": ""
    }
  ]
}
```

**Important:** The order of stories in prd.json does NOT imply priority. Ralph dynamically determines which story to work on next based on dependencies and codebase state.

---

## Story Size: The Number One Rule

**Each story must be completable in ONE Ralph iteration (one context window).**

Ralph spawns a fresh Claude Code instance per iteration with no memory of previous work. If a story is too big, the LLM runs out of context before finishing and produces broken code.

### Right-sized stories:
- Add a database column and migration
- Add a UI component to an existing page
- Update a server action with new logic
- Add a filter dropdown to a list

### Too big (split these):
- "Build the entire dashboard" - Split into: schema, queries, UI components, filters
- "Add authentication" - Split into: schema, middleware, login UI, session handling
- "Refactor the API" - Split into one story per endpoint or pattern

**Rule of thumb:** If you cannot describe the change in 2-3 sentences, it is too big.

---

## Story Dependencies (Guidance)

Ralph dynamically picks which story to work on, but be aware of natural dependencies when writing stories:

**Typical dependency order:**
1. Schema/database changes (migrations)
2. Server actions / backend logic
3. UI components that use the backend
4. Dashboard/summary views that aggregate data

Ralph will analyze the codebase and pick stories whose dependencies are satisfied. You don't need to enforce order - just write good stories and Ralph figures it out.

---

## Acceptance Criteria: Must Be Verifiable

Each criterion must be something Ralph can CHECK, not something vague.

### Good criteria (verifiable):
- "Add `status` column to tasks table with default 'pending'"
- "Filter dropdown has options: All, Active, Completed"
- "Clicking delete shows confirmation dialog"
- "Typecheck passes"
- "Tests pass"

### Bad criteria (vague):
- "Works correctly"
- "User can do X easily"
- "Good UX"
- "Handles edge cases"

### Always include these criteria on EVERY story:
```
"Typecheck passes"
"All tests pass"
```

**Adapt typecheck terminology to the project's tooling:**
- TypeScript/JavaScript: "Typecheck passes"
- PHP: "PHPStan analysis passes"
- Python: "Mypy passes"
- Go: "go vet passes"
- Rust: "cargo check passes"

**"All tests pass" is mandatory** - this ensures the test suite runs before every commit.

### For stories that change UI, also include:
```
"Verify in browser"
```

Frontend stories are NOT complete until visually verified. Ralph will navigate to the page, interact with the UI, and confirm changes work.

---

## Conversion Rules

1. **Each user story becomes one JSON entry**
2. **IDs**: Sequential (US-001, US-002, etc.)
3. **All stories**: `passes: false` and empty `notes`
4. **Always add**: "Typecheck passes" AND "All tests pass" to every story's acceptance criteria
5. **Include test requirements directly in acceptanceCriteria** (e.g., "Unit test: validates input", "Integration test: API returns created resource")
6. **First story should be test harness setup** if the project doesn't have test infrastructure

---

## Splitting Large PRDs

If a PRD has big features, split them:

**Original:**
> "Add user notification system"

**Split into:**
1. US-001: Add notifications table to database
2. US-002: Create notification service for sending notifications
3. US-003: Add notification bell icon to header
4. US-004: Create notification dropdown panel
5. US-005: Add mark-as-read functionality
6. US-006: Add notification preferences page

Each is one focused change that can be completed and verified independently.

---

## Example

**Input PRD:**
```markdown
# Task Status Feature

Add ability to mark tasks with different statuses.

## Requirements
- Toggle between pending/in-progress/done on task list
- Filter list by status
- Show status badge on each task
- Persist status in database
```

**Output prd.json:**
```json
{
  "project": "TaskApp",
  "description": "Task Status Feature - Track task progress with status indicators",
  "userStories": [
    {
      "id": "US-001",
      "title": "Add status field to tasks table",
      "description": "As a developer, I need to store task status in the database.",
      "acceptanceCriteria": [
        "Add status column: 'pending' | 'in_progress' | 'done' (default 'pending')",
        "Generate and run migration successfully",
        "Unit test: status column exists with correct type",
        "Unit test: default value is 'pending'",
        "Typecheck passes",
        "All tests pass"
      ],
      "passes": false,
      "notes": ""
    },
    {
      "id": "US-002",
      "title": "Display status badge on task cards",
      "description": "As a user, I want to see task status at a glance.",
      "acceptanceCriteria": [
        "Each task card shows colored status badge",
        "Badge colors: gray=pending, blue=in_progress, green=done",
        "Unit test: StatusBadge renders correct color for each status",
        "Integration test: TaskCard displays badge with task's status",
        "Typecheck passes",
        "All tests pass",
        "Verify in browser"
      ],
      "passes": false,
      "notes": ""
    },
    {
      "id": "US-003",
      "title": "Add status toggle to task list rows",
      "description": "As a user, I want to change task status directly from the list.",
      "acceptanceCriteria": [
        "Each row has status dropdown or toggle",
        "Changing status saves immediately",
        "UI updates without page refresh",
        "Unit test: status toggle cycles through states correctly",
        "Integration test: toggling status calls API and updates UI",
        "Typecheck passes",
        "All tests pass",
        "Verify in browser"
      ],
      "passes": false,
      "notes": ""
    },
    {
      "id": "US-004",
      "title": "Filter tasks by status",
      "description": "As a user, I want to filter the list to see only certain statuses.",
      "acceptanceCriteria": [
        "Filter dropdown: All | Pending | In Progress | Done",
        "Filter persists in URL params",
        "Unit test: filter function returns only matching tasks",
        "Integration test: selecting filter updates URL and displayed tasks",
        "Typecheck passes",
        "All tests pass",
        "Verify in browser"
      ],
      "passes": false,
      "notes": ""
    }
  ]
}
```

---

## Checklist Before Saving

Before writing prd.json, verify:

- [ ] Each story is completable in one iteration (small enough)
- [ ] Every story has "Typecheck passes" as criterion
- [ ] Every story has "All tests pass" as criterion
- [ ] Every story has specific test requirements in acceptanceCriteria (e.g., "Unit test: validates input")
- [ ] UI stories have "Verify in browser" as criterion
- [ ] Acceptance criteria are verifiable (not vague)
