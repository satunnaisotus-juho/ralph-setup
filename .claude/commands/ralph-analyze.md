---
description: "Analyze a completed Ralph implementation to identify PRD problems. Three-phase approach: explore first, compare second, validate third."
---

# PRD Analysis (Three-Phase)

**When to use:** After Ralph completes (or you stop it). Analyzes what went wrong to improve future PRDs and update LEARNINGS.md.

**Key principle:** Explore implementation BEFORE reading PRD. This prevents confirmation bias.

---

## Input

Gather upfront:

1. **Project Path:** Path to implementation (e.g., `~/workspace/my-project`)
2. **Example Name:** Name for `examples/<name>/` directory

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

Reference `examples/LEARNINGS.md` failure modes:

- `ARCHITECTURE_MISSING` - PRD described files, not runtime behavior
- `TESTS_NO_INFRA` - Required tests without test infrastructure
- `ASSUME_AVAILABLE` - Deferred core functionality to "assume exists"
- `CHECKPOINTS_IGNORED` - Validation stories had no enforcement
- `NO_CROSS_REFS` - Dependencies not stated at point of use
- `PATTERN_NOT_VALIDATED` - Pattern replicated before testing

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

---

## Output

### 4a. Create Example Directory

```
examples/<name>/
├── input/
│   └── request.md          # Ask user for original request
├── output/
│   ├── PRD.md              # Copy from .ralph/
│   ├── prd.json            # Copy from .ralph/
│   └── progress.txt        # Copy if exists
├── analysis/
│   ├── problems.md         # Structured problems (see format below)
│   └── improvements.md     # Optional, only if rewriting PRD
└── metadata.json
```

### 4b. Write problems.md

Use this concise format:

```markdown
# PRD Problems Analysis

**Project:** [name]
**Analyzed:** [date]
**Outcome:** [Working | Partial | Failed]
**Failure Modes:** [list codes from LEARNINGS.md]

## Summary

[2-3 sentences: what happened, why it failed]

## Problems

### 1. [Problem Title]

**Category:** [Failure mode code]
**Description:** [What went wrong]
**Evidence:** [Specific examples]
**Impact:** [How this affected the outcome]

---

[Repeat for each problem]
```

### 4c. Update LEARNINGS.md

Add a new entry to the Project Summaries section:

```markdown
### [project-name]

- **Outcome:** [Working | Partial | Failed]
- **Stories:** [X/Y passed]
- **Failure Mode:** `[CODE]`
- **Key Learning:** [One sentence from user]
- **What Happened:** [2-3 sentences]
```

If new anti-patterns were discovered, add them to the Anti-Patterns section.

---

## Completion Summary

```
## Analysis Complete

**Example:** examples/<name>/
**Outcome:** [Working | Partial | Failed]
**Failure Modes:** [list]
**Key Learning:** [one sentence]

**Files created:**
- examples/<name>/input/request.md
- examples/<name>/output/PRD.md
- examples/<name>/output/prd.json
- examples/<name>/analysis/problems.md
- examples/<name>/metadata.json

**LEARNINGS.md updated:** [Yes/No]
```

---

## Checklist

- [ ] Phase 1 completed WITHOUT reading PRD (no confirmation bias)
- [ ] Gaps categorized using LEARNINGS.md failure modes
- [ ] User confirmed outcome and failure mode
- [ ] Key learning captured in user's words
- [ ] LEARNINGS.md updated with new project entry
