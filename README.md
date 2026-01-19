# Ralph

![Ralph](ralph.webp)

Ralph is an autonomous AI agent loop that runs [Claude Code](https://claude.ai/code) repeatedly until all PRD items are complete. Each iteration is a fresh Claude Code instance with clean context. Memory persists via git history, `progress.txt`, and `prd.json`.

Based on [Geoffrey Huntley's Ralph pattern](https://ghuntley.com/ralph/).

[Read Ryan Carson's in-depth article on how he uses Ralph](https://x.com/ryancarson/status/2008548371712135632)

## Prerequisites

- [Claude Code CLI](https://claude.ai/code) installed and authenticated
- `jq` installed (`brew install jq` on macOS)
- A git repository for your project

## Quick Start

Initialize Ralph in your project with a single command:

```bash
# From the ralph directory
./init-ralph.sh /path/to/your/project
```

This copies all necessary files and sets up local Claude Code commands.

### Alternative: Install commands globally

If you prefer to have Ralph commands available across all projects:

```bash
mkdir -p ~/.claude/commands
cp .claude/commands/*.md ~/.claude/commands/
```

Note: You'll still need to copy `ralph.sh` and `prompt.md` to each project manually.

## Workflow

### 1. Create a PRD

Use the PRD command to generate a detailed requirements document:

```
/ralph-prd [your feature description]
```

Answer the clarifying questions. The command saves output to `tasks/prd-[feature-name].md`.

### 2. Convert PRD to Ralph format

Use the Ralph command to convert the markdown PRD to JSON:

```
/ralph tasks/prd-[feature-name].md
```

This creates `prd.json` with user stories structured for autonomous execution.

### 3. Run Ralph

```bash
./ralph.sh [max_iterations]
```

Default is 10 iterations.

### Troubleshooting: Fix Inconsistencies

If Ralph is behaving unexpectedly, use the fix-inconsistencies command to audit system files:

```
/ralph-fix-inconsistencies
```

This checks `ralph.sh`, `prompt.md`, `prd.json`, and `PRD.md` for alignment issues and fixes them.

Ralph will:
1. Dynamically pick a story where `passes: false` (based on dependencies and codebase state)
2. Implement that single story
3. Run quality checks (typecheck, tests)
4. Commit if checks pass
5. Update `prd.json` to mark story as `passes: true`
6. Append learnings to `progress.txt`
7. Repeat until all stories pass or max iterations reached

## Key Files

| File | Purpose |
|------|---------|
| `ralph.sh` | The bash loop that spawns fresh Claude Code instances |
| `prompt.md` | Instructions given to each Claude Code instance |
| `prd.json` | User stories with `passes` status (the task list) |
| `prd.json.example` | Example PRD format for reference |
| `progress.txt` | Append-only learnings for future iterations |
| `prettify-ralph.sh` | Log prettifier for monitoring Ralph in real-time |
| `init-ralph.sh` | Initializes Ralph in a new project directory |
| `CLAUDE.md` | Project context for Claude Code |
| `AGENTS.md` | Instructions for Ralph agent iterations |
| `.claude/commands/ralph-prd.md` | Command for generating PRDs |
| `.claude/commands/ralph.md` | Command for converting PRDs to JSON |
| `.claude/commands/ralph-fix-inconsistencies.md` | Command for auditing system file consistency |
| `flowchart/` | Interactive visualization of how Ralph works |

## Flowchart

[![Ralph Flowchart](ralph-flowchart.png)](https://snarktank.github.io/ralph/)

**[View Interactive Flowchart](https://snarktank.github.io/ralph/)** - Click through to see each step with animations.

The `flowchart/` directory contains the source code. To run locally:

```bash
cd flowchart
npm install
npm run dev
```

## Critical Concepts

### Each Iteration = Fresh Context

Each iteration spawns a **new Claude Code instance** with clean context. The only memory between iterations is:
- Git history (commits from previous iterations)
- `progress.txt` (learnings and context)
- `prd.json` (which stories are done)

### Small Tasks

Each PRD item should be small enough to complete in one context window. If a task is too big, the LLM runs out of context before finishing and produces poor code.

Right-sized stories:
- Add a database column and migration
- Add a UI component to an existing page
- Update a server action with new logic
- Add a filter dropdown to a list

Too big (split these):
- "Build the entire dashboard"
- "Add authentication"
- "Refactor the API"

### AGENTS.md Updates Are Critical

After each iteration, Ralph updates the relevant `AGENTS.md` files with learnings. This is key because Claude Code automatically reads these files, so future iterations (and future human developers) benefit from discovered patterns, gotchas, and conventions.

Examples of what to add to AGENTS.md:
- Patterns discovered ("this codebase uses X for Y")
- Gotchas ("do not forget to update Z when changing W")
- Useful context ("the settings panel is in component X")

### Feedback Loops

Ralph only works if there are feedback loops:
- Typecheck catches type errors
- Tests verify behavior
- CI must stay green (broken code compounds across iterations)

### Browser Verification for UI Stories

Frontend stories must include "Verify in browser" in acceptance criteria. Ralph will navigate to the page, interact with the UI, and confirm changes work.

### Stop Condition

When all stories have `passes: true`, Ralph outputs `<promise>COMPLETE</promise>` and the loop exits.

## Monitoring Ralph

While Ralph is running, you can watch its progress in real-time with the log prettifier:

```bash
# In a separate terminal, tail the log with pretty formatting
tail -f ralph-log.json | ./prettify-ralph.sh
```

This shows a Claude Code-like view with:
- Session banners (model, working directory)
- Claude's thoughts and reasoning
- Tool calls (Read, Write, Edit, Bash, etc.)
- Results with success/error indicators
- Completion stats (duration, cost, turns)

You can also review a completed log:

```bash
cat ralph-log.json | ./prettify-ralph.sh
```

## Debugging

Check current state:

```bash
# See which stories are done
cat prd.json | jq '.userStories[] | {id, title, passes}'

# See learnings from previous iterations
cat progress.txt

# Check git history
git log --oneline -10
```

## Customizing prompt.md

Edit `prompt.md` to customize Ralph's behavior for your project:
- Add project-specific quality check commands
- Include codebase conventions
- Add common gotchas for your stack

## References

- [Geoffrey Huntley's Ralph article](https://ghuntley.com/ralph/)
- [Claude Code documentation](https://docs.anthropic.com/en/docs/claude-code)
