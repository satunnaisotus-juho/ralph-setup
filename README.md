# Ralph

![Ralph](ralph.webp)

Ralph is an autonomous AI agent loop that runs [Claude Code](https://claude.ai/code) repeatedly until all PRD items are complete. Each iteration is a fresh Claude Code instance with clean context. Memory persists via git history, `.ralph/progress.txt`, and `.ralph/prd.json`.

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

Note: You'll still need to copy the `.ralph/` directory (containing `ralph.sh` and `prompt.md`) to each project manually.

## Workflow

### 1. Create a PRD

Use the PRD command to generate a detailed requirements document:

```
/ralph-prd [your feature description]
```

Answer the clarifying questions. The command saves output to `.ralph/PRD.md`.

### 2. Convert PRD to Ralph format

Use the Ralph command to convert the markdown PRD to JSON:

```
/ralph-prd-to-json .ralph/PRD.md
```

This creates `.ralph/prd.json` with user stories structured for autonomous execution.

### 3. Initialize Git and Push to GitHub

If this is a new project, initialize git and push to GitHub:

```
/ralph-git-init
```

This asks for your GitHub username and repository name, then creates an initial commit with your PRD and pushes to GitHub.

### 4. Run Ralph

```bash
./.ralph/ralph.sh [max_iterations]
```

Default is 10 iterations.

## Remote Deployment (Unsecured System)

If you want to run Ralph on a separate unsecured system (e.g., with `--dangerously-skip-permissions`), you can deploy with scoped access using SSH deploy keys:

```bash
./init-ralph.sh /path/to/project user@remote-host /remote/path
```

This will:
1. Generate a project-specific SSH deploy key
2. Add it to GitHub (requires `gh` CLI, or shows manual instructions)
3. Transfer the private key to the remote system's `~/.ssh/`
4. Copy Ralph files to the remote system
5. Initialize git on the remote, create initial commit, and push

**Prerequisites:**
- SSH access to the remote system
- `gh` CLI (optional, for automatic deploy key setup)
- A GitHub repository URL (you'll be prompted if not already configured)

The deploy key grants access **only to that specific repository**, not your other repos. This is safer than giving the unsecured system your main SSH keys.

After deployment, run Ralph on the remote system:
```bash
ssh user@remote-host
cd /remote/path/your-project
./.ralph/ralph.sh
```

### Troubleshooting: Fix Inconsistencies

If Ralph is behaving unexpectedly, use the fix-inconsistencies command to audit system files:

```
/ralph-fix-inconsistencies
```

This checks `.ralph/ralph.sh`, `.ralph/prompt.md`, `.ralph/prd.json`, and `.ralph/PRD.md` for alignment issues and fixes them.

Ralph will:
1. Dynamically pick a story where `passes: false` (based on dependencies and codebase state)
2. Implement that single story
3. Run quality checks (typecheck, tests)
4. Commit if checks pass
5. Update `.ralph/prd.json` to mark story as `passes: true`
6. Append learnings to `.ralph/progress.txt`
7. Repeat until all stories pass or max iterations reached

## Key Files

| File | Purpose |
|------|---------|
| `.ralph/ralph.sh` | The bash loop that spawns fresh Claude Code instances |
| `.ralph/prompt.md` | Instructions given to each Claude Code instance |
| `.ralph/prd.json` | User stories with `passes` status (the task list) |
| `.ralph/prd.json.example` | Example PRD format for reference |
| `.ralph/progress.txt` | Append-only learnings for future iterations |
| `.ralph/prettify-ralph.sh` | Log prettifier for monitoring Ralph in real-time |
| `init-ralph.sh` | Initializes Ralph in a new project directory (in ralph-setup) |
| `CLAUDE.md` | Project context for Claude Code |
| `AGENTS.md` | Instructions for Ralph agent iterations |
| `.claude/commands/ralph-prd.md` | Command for generating PRDs |
| `.claude/commands/ralph-prd-to-json.md` | Command for converting PRDs to JSON |
| `.claude/commands/ralph-fix-inconsistencies.md` | Command for auditing system file consistency |
| `.claude/commands/ralph-git-init.md` | Command for initializing git and pushing to GitHub |

## Critical Concepts

### Each Iteration = Fresh Context

Each iteration spawns a **new Claude Code instance** with clean context. The only memory between iterations is:
- Git history (commits from previous iterations)
- `.ralph/progress.txt` (learnings and context)
- `.ralph/prd.json` (which stories are done)

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
tail -f .ralph/ralph-log.json | ./.ralph/prettify-ralph.sh
```

This shows a Claude Code-like view with:
- Session banners (model, working directory)
- Claude's thoughts and reasoning
- Tool calls (Read, Write, Edit, Bash, etc.)
- Results with success/error indicators
- Completion stats (duration, cost, turns)

You can also review a completed log:

```bash
cat .ralph/ralph-log.json | ./.ralph/prettify-ralph.sh
```

## Debugging

Check current state:

```bash
# See which stories are done
cat .ralph/prd.json | jq '.userStories[] | {id, title, passes}'

# See learnings from previous iterations
cat .ralph/progress.txt

# Check git history
git log --oneline -10
```

## Customizing prompt.md

Edit `.ralph/prompt.md` to customize Ralph's behavior for your project:
- Add project-specific quality check commands
- Include codebase conventions
- Add common gotchas for your stack

## References

- [Geoffrey Huntley's Ralph article](https://ghuntley.com/ralph/)
- [Claude Code documentation](https://docs.anthropic.com/en/docs/claude-code)
