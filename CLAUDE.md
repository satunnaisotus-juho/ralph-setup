# CLAUDE.md

This file provides guidance to Claude Code (claude.ai/code) when working with code in this repository.

## Project Overview

Ralph is an autonomous AI agent loop that runs [Claude Code](https://claude.ai/code) repeatedly until all PRD items are complete. Each iteration spawns a fresh Claude Code instance with clean context. Memory persists via git history, `progress.txt`, and `prd.json`.

Based on [Geoffrey Huntley's Ralph pattern](https://ghuntley.com/ralph/).

## Commands

### Ralph Agent Loop

```bash
./ralph.sh [max_iterations]   # Run from directory with prd.json (default: 10 iterations)
```

## Architecture

### Core Components

1. **ralph.sh** - Bash orchestration loop that:
   - Spawns fresh Claude Code instances with `prompt.md`
   - Checks for `<promise>COMPLETE</promise>` completion signal (must be on its own line)
   - Displays elapsed time and iteration duration

2. **prompt.md** - Instructions for each Claude Code iteration defining the agent workflow

3. **.claude/commands/** - Claude Code command definitions:
   - `ralph-prd.md` - Generates structured PRD from feature description
   - `ralph-prd-to-json.md` - Converts markdown PRD to `prd.json` format
   - `ralph-fix-inconsistencies.md` - Audits Ralph system files for consistency
   - `ralph-git-init.md` - Initialize git repository and push to GitHub

### PRD Format (`prd.json`)

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

Note: The order of stories in prd.json does NOT imply priority. Ralph dynamically determines which story to work on next.

### State Files

- `prd.json` - Task list with user stories and `passes` status
- `progress.txt` - Append-only learnings log

## Key Patterns

### Story Sizing
Stories must be completable in ONE context window:
- Right: "Add database column", "Add UI component", "Update server action"
- Wrong: "Build entire dashboard", "Add authentication"

### Iteration Workflow
1. Read `prd.json` and `progress.txt`
2. Dynamically pick a story where `passes: false` (based on dependencies and codebase state)
3. Implement, run quality checks, commit if passing
4. Update `prd.json` to mark `passes: true`
5. Append learnings to `progress.txt`
6. **STOP** - one story per iteration (a fresh Claude instance handles the next)
7. Output `<promise>COMPLETE</promise>` only when ALL stories pass

### AGENTS.md Updates
Discovered patterns should be added to relevant `AGENTS.md` files for future iterations.

### Commit Format
Commits should include detailed context. See `prompt.md` for the full template. Summary:
```
feat: [Story ID] - [Story Title]

## Summary
[What was implemented]

## Story Goal
[The "why" from prd.json]

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
