---
description: "Analyze a completed Ralph implementation to identify PRD problems and improvements. Interactive human-in-the-loop analysis for iterating on PRD quality."
---

# PRD Feedback Analyzer

**When to use:** After Ralph has completed all stories (or you've stopped it). This analyzes what went well/poorly to improve future PRDs.

Analyze completed Ralph implementations to identify problems with the original PRD and generate actionable improvements. This is an interactive process - you ask questions, the human provides ground truth.

---

## The Job

1. Gather context from the implementation (PRD.md, prd.json, codebase, git history)
2. Ask targeted questions to understand what went wrong
3. Collaboratively identify problems and improvements
4. Write validated analysis to the example directory

**Key Principle:** You assist and structure. The human provides ground truth.

---

## Input

The user will provide one of:
- Path to a completed implementation directory (with PRD.md, prd.json, codebase)
- Path to an example in `examples/` directory
- A PRD file directly

If no path provided, ask:
```
What implementation should I analyze?
A. A completed Ralph project (provide path)
B. An example in the examples/ directory
C. A PRD file directly (paste or provide path)
```

---

## Phase 1: Context Gathering

1. **Read the artifacts:**
   - PRD.md (the original PRD)
   - prd.json (the converted stories)
   - Explore the codebase structure
   - Check git history for patterns (optional)

2. **Summarize what you found:**
   - Number of stories, high-level scope
   - Types of work (UI, API, database, etc.)
   - Any obvious structural observations

3. **Ask the opening question:**
   ```
   I've reviewed the PRD and implementation. Before I ask specific questions:

   What was your overall experience with this PRD during implementation?
   What stood out as problematic or friction-causing?
   ```

---

## Phase 2: Problem Identification (Interactive)

Ask these questions one at a time or in small batches. Wait for human answers.

### Story Sizing
```
Were any stories too large for a single context window?
Which ones, and what made them too big?
```

### Acceptance Criteria
```
Which acceptance criteria were unclear, incomplete, or wrong?
Were there things you had to figure out that should have been specified?
```

### Dependencies
```
Were there hidden dependencies between stories that caused problems?
Did you have to implement stories in a different order than expected?
```

### Ambiguity
```
What specifications were ambiguous and led to guessing or rework?
What assumptions did the PRD make that turned out to be wrong?
```

### Missing Requirements
```
What requirements were missing entirely?
What did you have to add that wasn't in the PRD?
```

After the human answers, you may suggest additional problems based on:
- Git history patterns (multiple commits per story suggests it was too big)
- Codebase structure vs PRD organization
- Common anti-patterns you notice

**Always confirm your suggestions with the human:**
```
Based on [evidence], I suspect [problem]. Does this match your experience?
```

---

## Phase 3: Improvement Suggestions (Collaborative)

For each validated problem, work with the human to articulate improvements.

**Structure each improvement as:**
1. **Problem:** What went wrong
2. **Evidence:** Specific examples from this implementation
3. **Improvement:** How the PRD should have been written differently
4. **Generalized Guidance:** Rule for future PRDs

**Ask the human:**
```
For [problem], how do you think the PRD should have been different?
What would have prevented this issue?
```

Then help articulate and structure their input.

---

## Phase 4: Output Generation

### 4a. Determine Output Location

If analyzing an example in `examples/`:
- Write to `examples/<name>/analysis/`

If analyzing an external project:
```
Where should I save the analysis?
A. Create a new example in examples/<name>/
B. Save to the project directory itself
C. Just output here (don't save files)
```

### 4b. Write problems.md

```markdown
# PRD Problems Analysis

**Project:** [name]
**Analyzed:** [date]
**PRD Version:** [if known]

## Summary

[Brief overview of key problems found]

## Problems

### 1. [Problem Title]

**Category:** [Story Sizing | Acceptance Criteria | Dependencies | Ambiguity | Missing Requirements]

**Description:** [What went wrong]

**Evidence:** [Specific examples from implementation]

**Impact:** [How this affected implementation]

---

[Repeat for each problem]
```

### 4c. Write improvements.md

```markdown
# PRD Improvement Suggestions

**Project:** [name]
**Based on:** problems.md analysis

## Summary

[Key themes and patterns in the improvements]

## Improvements

### 1. [Improvement Title]

**Addresses Problem:** [Reference to problem]

**Current PRD Approach:**
> [Quote or describe what the PRD said]

**Recommended Approach:**
> [How it should have been written]

**Generalized Rule:**
[Guidance for future PRDs]

---

[Repeat for each improvement]

## Action Items for /ralph-prd

These improvements should be incorporated into the PRD generator:

- [ ] [Specific change to make]
- [ ] [Another change]
```

### 4d. Optionally Write PRD-improved.md

If the human wants to see a revised PRD:
```
Would you like me to draft an improved version of the PRD incorporating these learnings?
```

If yes, rewrite the PRD with improvements applied, noting changes inline.

---

## Output Summary

When complete, provide:

```
## Analysis Complete

**Files written:**
- `analysis/problems.md` - [N] problems identified
- `analysis/improvements.md` - [N] improvements suggested
- `analysis/PRD-improved.md` - [if created]

**Key Themes:**
- [Theme 1]
- [Theme 2]

**Next Steps:**
- Review the improvements.md action items
- Consider updating /ralph-prd command based on learnings
```

---

## Checklist

Before completing:

- [ ] Read and understood the PRD and implementation
- [ ] Asked questions and received human input
- [ ] Problems are validated by human, not just auto-generated
- [ ] Improvements include specific evidence from this implementation
- [ ] Generalized rules are actionable for future PRDs
- [ ] Output files are written (if requested)
