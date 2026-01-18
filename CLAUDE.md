# CLAUDE.md

This file provides guidance to Claude Code (claude.ai/code) when working with code in this repository.

## Project Overview

Ralph is an autonomous AI agent loop that runs [Claude Code](https://claude.ai/code) repeatedly until all PRD items are complete. Each iteration spawns a fresh Claude Code instance with clean context. Memory persists via git history, `progress.txt`, and `prd.json`.

Based on [Geoffrey Huntley's Ralph pattern](https://ghuntley.com/ralph/).

## Commands

### Flowchart (React visualization)

```bash
cd flowchart && npm install   # Install dependencies
cd flowchart && npm run dev   # Development server with HMR
cd flowchart && npm run build # Production build (tsc -b && vite build)
cd flowchart && npm run lint  # ESLint
```

### Ralph Agent Loop

```bash
./ralph.sh [max_iterations]   # Run from directory with prd.json (default: 10 iterations)
```

## Architecture

### Core Components

1. **ralph.sh** - Bash orchestration loop that:
   - Archives previous runs when branch changes (to `archive/YYYY-MM-DD-feature-name/`)
   - Spawns fresh Claude Code instances with `prompt.md`
   - Checks for `<promise>COMPLETE</promise>` completion signal
   - Tracks state via `.last-branch` file

2. **prompt.md** - Instructions for each Claude Code iteration defining the agent workflow

3. **.claude/commands/** - Claude Code command definitions:
   - `prd.md` - Generates structured PRD from feature description
   - `ralph.md` - Converts markdown PRD to `prd.json` format

4. **flowchart/** - Interactive React Flow visualization deployed to GitHub Pages at `/ralph/`

### PRD Format (`prd.json`)

```json
{
  "project": "ProjectName",
  "branchName": "ralph/feature-name",
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

### State Files (gitignored)

- `prd.json` - Task list with user stories and `passes` status
- `progress.txt` - Append-only learnings log
- `.last-branch` - Tracks current feature branch

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
6. Output `<promise>COMPLETE</promise>` when all done

### AGENTS.md Updates
Discovered patterns should be added to relevant `AGENTS.md` files for future iterations.

### Commit Format
```
feat: [Story ID] - [Story Title]

Co-Authored-By: Claude Opus 4.5 <noreply@anthropic.com>
```
