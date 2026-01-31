# CLAUDE.md

This file provides guidance to Claude Code (claude.ai/code) when working with code in this repository.

## Project Overview

Ralph is an autonomous AI agent loop that runs [Claude Code](https://claude.ai/code) repeatedly until all PRD items are complete. Each iteration spawns a fresh Claude Code instance with clean context. Memory persists via git history, `.ralph/prd.json`, and `.ralph/implementation-notes.md`.

Based on [Geoffrey Huntley's Ralph pattern](https://ghuntley.com/ralph/).

## Commands

### Ralph Agent Loop

```bash
./.ralph/ralph.sh [max_iterations]   # Run from directory with .ralph/ (default: 10 iterations)
```

## Architecture

### Core Components

1. **.ralph/ralph.sh** - Bash orchestration loop that:
   - Spawns fresh Claude Code instances with `.ralph/prompt.md`
   - Checks for `<promise>COMPLETE</promise>` completion signal (must be on its own line)
   - Displays elapsed time and iteration duration

2. **.ralph/prompt.md** - Instructions for each Claude Code iteration defining the agent workflow

3. **.claude/commands/** - Claude Code command definitions:
   - `ralph-prd.md` - Generates structured PRD from feature description
   - `ralph-prd-to-json.md` - Converts markdown PRD to `.ralph/prd.json` format
   - `ralph-analyze.md` - Interactive PRD feedback analysis (run after Ralph completes)
   - `ralph-fix-inconsistencies.md` - Audits Ralph system files for consistency
   - `ralph-git-init.md` - Initialize git repository and push to GitHub

### PRD Format (`.ralph/prd.json`)

```json
{
  "project": "ProjectName",
  "userStories": [
    {
      "id": "US-001",
      "title": "Story title",
      "acceptanceCriteria": ["Criterion 1"],
      "passes": false
    }
  ]
}
```

Note: The order of stories in `.ralph/prd.json` does NOT imply priority. Ralph dynamically determines which story to work on next.

### State Files (in `.ralph/`)

- `prd.json` - Task list with user stories and `passes` status
- `implementation-notes.md` - Compact codebase patterns (not per-story logs)
- `reference-implementations.md` - GitHub repos analyzed for patterns (created during PRD generation)

## Key Patterns

### Story Sizing
Stories must be completable in ONE context window:
- Right: "Add database column", "Add UI component", "Update server action"
- Wrong: "Build entire dashboard", "Add authentication"

### Iteration Workflow
1. Read `.ralph/prd.json` and `.ralph/implementation-notes.md`
2. Read recent git history (`git log --oneline -10`) for context
3. Dynamically pick a story where `passes: false` (based on dependencies and codebase state)
4. **Pre-implementation research**: Check reference implementations, web search for best practices
5. Implement, run quality checks
6. **Post-implementation**: Update `.ralph/implementation-notes.md` with codebase learnings
7. Update `.ralph/prd.json` to mark `passes: true`
8. Commit if passing (include all state files)
9. **STOP** - one story per iteration (a fresh Claude instance handles the next)
10. Output `<promise>COMPLETE</promise>` only when ALL stories pass

### Commit Format
Commits should include detailed context. See `.ralph/prompt.md` for the full template. Summary:
```
feat: [Story ID] - [Story Title]

## Summary
[What was implemented]

## Story Goal
[The "why" from .ralph/prd.json]

## Changes
- [File]: [What changed]

## Acceptance Criteria Met
- [x] [Criteria from story]

## Testing
- [How verified]

## Notes (optional)
- [Gotchas, decisions]

Co-Authored-By: Claude Opus 4.5 <noreply@anthropic.com>
```
