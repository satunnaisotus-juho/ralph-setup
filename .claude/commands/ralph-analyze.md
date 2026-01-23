---
description: "Analyze a completed Ralph implementation. Three-phase approach: explore first, compare second, validate third. Appends to dataset/runs.jsonl."
---

# PRD Analysis (Three-Phase)

**When to use:** After Ralph completes (or you stop it). Analyzes what went wrong to improve future PRDs.

**Key principle:** Explore implementation BEFORE reading PRD. This prevents confirmation bias.

**Output:** Appends structured entry to `dataset/runs.jsonl` + copies artifacts.

---

## Input

Gather upfront:

1. **Project Path:** Path to implementation (e.g., `~/workspace/my-project`)
2. **Run ID:** Unique identifier (e.g., `my-project-2026-01-23`)

Validate path exists and contains `.ralph/` directory.

---

## Phase 1: Implementation Analysis (NO PRD)

**CRITICAL: Do NOT read the PRD during this phase.**

### 1a. Explore the Codebase

Thoroughly explore the implementation:
- Directory structure and file organization
- Main entry points and how they connect
- What dependencies are used
- What the code actually does (not what it claims to do)

### 1b. Document Findings (Before PRD)

Answer these questions based solely on code exploration:

1. **What does this system do?** (One paragraph)
2. **What are the main components?** (List with brief descriptions)
3. **Does it look complete?** (Yes/No with reasoning)
4. **What's obviously missing or broken?** (List)
5. **What patterns/conventions does it follow?** (List)

Write notes to yourself - you'll compare against PRD in Phase 2.

---

## Phase 2: PRD Comparison

**NOW read the PRD and prd.json.**

### 2a. Read PRD Artifacts

From `<project-path>/.ralph/`:
- `PRD.md` or equivalent
- `prd.json`
- `progress.txt` (if exists)
- `implementation-notes.md` (if exists)

### 2b. Compare: PRD vs Reality

For each major PRD section/story:

| PRD Promised | What Was Built | Gap |
|--------------|----------------|-----|
| ... | ... | ... |

### 2c. Categorize Gaps

Reference `dataset/failure-modes.md` for the taxonomy:

- `ARCHITECTURE_MISSING` - PRD described files, not runtime behavior
- `TESTS_NO_INFRA` - Required tests without test infrastructure
- `ASSUME_AVAILABLE` - Deferred core functionality to "assume exists"
- `CHECKPOINTS_IGNORED` - Validation stories had no enforcement
- `NO_CROSS_REFS` - Dependencies not stated at point of use
- `PATTERN_NOT_VALIDATED` - Pattern replicated before testing
- `MANUAL_CHECKPOINTS` - Checkpoints require human intervention
- `PERMISSIONS_NOT_DECLARED` - Permission requirements hidden

Identify which failure modes apply.

---

## Phase 3: Human Validation

Ask the user these questions:

### 3a. Outcome Question
```
Did the project actually work when you tried to use it?
- Yes, it works as intended
- Partial - some parts work
- No, it doesn't work despite stories passing
```

### 3b. If Partial or No
```
What was the main reason it failed? (Pick one or describe)
- Built files but they don't integrate at runtime
- Tests missing despite being required
- Core functionality deferred to "assume available"
- Checkpoints marked passed but weren't validated
- Dependencies unclear, had to guess order
- Pattern was wrong but replicated everywhere
- Other: [describe]
```

### 3c. Key Learning
```
In one sentence, what's the most important lesson from this project?
```

### 3d. Improvements
```
What specific changes to ralph-prd or prompt.md would prevent this?
```

---

## Output

### 4a. Copy Artifacts

Create artifact directory structure:

```
dataset/artifacts/<run-id>/
├── implementation/           # From the project's .ralph/
│   ├── PRD.md
│   ├── prd.json
│   ├── progress.txt
│   ├── implementation-notes.md
│   └── initiation-chat.md    # Discovery conversation that produced PRD
└── snapshots/                # Tool versions at time of run
    ├── ralph-prd.md
    ├── prompt.md
    └── ralph.sh
```

```bash
# Create directories
mkdir -p dataset/artifacts/<run-id>/implementation
mkdir -p dataset/artifacts/<run-id>/snapshots

# Copy implementation artifacts (from project's .ralph/)
cp <project-path>/.ralph/PRD.md dataset/artifacts/<run-id>/implementation/
cp <project-path>/.ralph/prd.json dataset/artifacts/<run-id>/implementation/
cp <project-path>/.ralph/progress.txt dataset/artifacts/<run-id>/implementation/ 2>/dev/null || true
cp <project-path>/.ralph/implementation-notes.md dataset/artifacts/<run-id>/implementation/ 2>/dev/null || true
cp <project-path>/.ralph/initiation-chat.md dataset/artifacts/<run-id>/implementation/ 2>/dev/null || true

# Copy tool snapshots (from ralph-setup repo)
cp .claude/commands/ralph-prd.md dataset/artifacts/<run-id>/snapshots/
cp .ralph/prompt.md dataset/artifacts/<run-id>/snapshots/
cp .ralph/ralph.sh dataset/artifacts/<run-id>/snapshots/
```

### 4b. Append to runs.jsonl

Append ONE JSON line to `dataset/runs.jsonl`:

```json
{
  "id": "<run-id>",
  "created": "<YYYY-MM-DD>",
  "versions": {
    "ralph_prd": "<commit or version>",
    "prompt_md": "<commit or version>",
    "ralph_sh": "<commit or version>"
  },
  "input": {
    "request_summary": "<1-2 sentence description of what was requested>",
    "stories_total": <number>
  },
  "output": {
    "stories_passed": <number>,
    "outcome": "<working|partial|failed>"
  },
  "analysis": {
    "works": <true|false>,
    "failure_modes": ["<CODE1>", "<CODE2>"],
    "learning": "<key learning from user>",
    "improvements": ["<specific improvement 1>", "<specific improvement 2>"]
  }
}
```

**Important:** Use `jq` to validate JSON before appending:
```bash
echo '<json>' | jq . && echo '<json>' >> dataset/runs.jsonl
```

---

## Completion Summary

```
## Analysis Complete

**Run ID:** <run-id>
**Outcome:** <working|partial|failed>
**Failure Modes:** <list>
**Key Learning:** <one sentence>

**Artifacts captured:**
- dataset/artifacts/<run-id>/implementation/  (PRD.md, prd.json, progress.txt, initiation-chat.md, etc.)
- dataset/artifacts/<run-id>/snapshots/       (ralph-prd.md, prompt.md, ralph.sh)

**Appended to:** dataset/runs.jsonl

**Query this run:**
cat dataset/runs.jsonl | jq 'select(.id == "<run-id>")'

**Query all failures:**
cat dataset/runs.jsonl | jq 'select(.analysis.works == false)'
```

---

## Checklist

- [ ] Phase 1 completed WITHOUT reading PRD (no confirmation bias)
- [ ] Gaps categorized using failure-modes.md taxonomy
- [ ] User confirmed outcome and failure mode
- [ ] Key learning captured in user's words
- [ ] Improvements are specific and actionable
- [ ] JSON validated with jq before appending
- [ ] Implementation artifacts copied (PRD.md, prd.json, progress.txt, implementation-notes.md, initiation-chat.md)
- [ ] Tool snapshots copied (ralph-prd.md, prompt.md, ralph.sh)
