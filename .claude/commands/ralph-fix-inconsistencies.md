---
description: "Analyze Ralph system files for inconsistencies and fix them. Checks ralph.sh, prompt.md, prd.json, and PRD.md for alignment issues."
---

# Ralph Inconsistency Checker

Analyze the Ralph autonomous agent system files and fix any inconsistencies between them.

---

## Files to Analyze

Read and cross-reference these files:

1. **ralph.sh** - The bash loop script that runs iterations
2. **prompt.md** - Instructions given to each Ralph iteration
3. **prd.json** - The structured task list with user stories
4. **PRD.md** - The human-readable Product Requirements Document (if exists)
5. **.claude/commands/ralph.md** - The PRD converter command
6. **progress.txt** - The progress log
7. **.gitignore** - Ensure Ralph state files are ignored

---

## What to Check

### 1. File Format Consistency
- Does `progress.txt` match the format that `ralph.sh` generates via `reset_progress_file()`?
- Does the story count in `progress.txt` match the actual count in `prd.json`?
- Are all backup/state files listed in `.gitignore`?

### 2. Cross-File References
- Does `prompt.md` reference the correct file names?
- Are acceptance criteria terminology consistent across files?
- Does the story count in `prd.json` match what's documented in `PRD.md`?

### 3. Archive Mechanism
- Does `ralph.sh` properly handle backup files for archiving?
- Is the archiving documentation in `ralph.md` accurate?

### 4. State Files
- Are all state files (.last-branch, .prd.json.bak, .progress.txt.bak) in `.gitignore`?
- Is branch handling logic in `prompt.md` clear?

### 5. Completion Signal
- Does the completion signal pattern in `ralph.sh` match what's documented in `prompt.md`?
- Is the warning about not quoting the signal present?

---

## Output

For each inconsistency found:
1. Describe the issue
2. Show which files conflict
3. Fix the issue
4. Explain the fix

If no inconsistencies are found, confirm the system is consistent.
