---
description: "Generate a Product Requirements Document (PRD) for a new feature. Use when planning a feature, starting a new project, or when asked to create a PRD."
---

# PRD Generator v3 (Test-Focused)

Create PRDs that prioritize **testability** from the start. Every project begins with test infrastructure, and every story includes test requirements.

**Key principle:** Test harness first, features second. All stories must pass the test suite before completion.

---

## The Job

A 3-phase conversation:

1. **Phase 1: Discovery** - Understand the problem, users, scope, and edge cases
2. **Phase 2: Architecture & Test Strategy** - Tech stack AND testing approach together
3. **Phase 3: Generate PRD** - Write PRD.md and prd.json with test-first stories

**Important:** Do NOT start implementing. Create the PRD and get user approval first.

---

## Phase 1: Discovery

Understand the full picture before making technical decisions.

**Cover these areas (use AskUserQuestion for structured choices):**

- **Problem & goals:** What are we solving? Why does it matter?
- **Users:** Who benefits? Who are the primary users?
- **Scope:** What's the minimal viable scope? What's explicitly out?
- **Happy path:** Walk through the ideal user flow step by step
- **Edge cases:** What can go wrong? How should errors be handled?
- **Integrations:** What external systems are involved?

**Quick codebase check:** If the directory has existing code, briefly scan for existing test infrastructure before proceeding.

**Goal:** Build a complete mental model before discussing implementation.

---

## Phase 2: Architecture & Test Strategy

Tech decisions and testing decisions inform each other - make them together.

**Cover these areas:**

### Technical Architecture
- What's the tech stack? (framework, language, database)
- What are the main components and how do they connect?
- What's the data flow?

### Test Strategy
Based on the tech stack, determine:

- **Test framework:** What testing tools fit this stack?
  - Node/TS: Vitest, Jest, Playwright
  - Python: pytest, unittest
  - Go: testing package, testify
  - etc.

- **Test types needed:**
  - **Unit tests:** Isolated logic, pure functions, utilities
  - **Integration tests:** Components working together, API endpoints, database operations
  - **E2E tests:** Full user flows (if applicable - usually for web apps)

- **What gets tested:**
  - Core business logic → unit tests
  - API endpoints → integration tests
  - User-facing flows → E2E tests
  - Edge cases and error handling → unit + integration

**Goal:** Clear technical approach AND clear testing approach before writing stories.

---

## Phase 3: Generate PRD

Write two files:
1. `.ralph/PRD.md` - Human-readable documentation
2. `.ralph/prd.json` - Machine-readable for Ralph execution

### PRD.md Structure

```markdown
# PRD: [Feature Name]

## 1. Problem Statement
What problem are we solving and why it matters.

## 2. Goals
Specific, measurable objectives (bullet list).

## 3. How It Works
Explain the execution model:
- How do the pieces connect at runtime?
- What calls what?
- What's the data flow?

Include a simple diagram if helpful:
```
User action → Component A → Component B → Result
                  ↓
            Component C (async)
```

## 4. Test Strategy
- **Test framework:** [framework name]
- **Test command:** `[e.g., npm test]`
- **Unit tests:** [what they cover]
- **Integration tests:** [what they cover]
- **E2E tests:** [what they cover, if applicable]

## 5. User Stories
[See story format below]

## 6. Non-Goals
What this explicitly does NOT include.

## 7. Open Questions
Remaining uncertainties.
```

---

## Story Format

### Foundation Story (Always US-001)

The first story is ALWAYS test harness setup:

```markdown
### US-001: Set up test harness
**Description:** As a developer, I need test infrastructure so all future work is verified before commits.

**Acceptance Criteria:**
- [ ] Test framework installed and configured
- [ ] Unit test setup working (example test passes)
- [ ] Integration test setup working (example test passes)
- [ ] E2E test setup if applicable (example test passes)
- [ ] Test command documented (e.g., `npm test`)
- [ ] Tests run successfully in CI/headless mode
- [ ] Typecheck passes
- [ ] All tests pass
```

### Feature Stories

```markdown
### US-XXX: [Title]
**Description:** As a [user], I want [feature] so that [benefit].

**Acceptance Criteria:**
- [ ] [Functional criterion - specific and verifiable]
- [ ] [Another criterion]
- [ ] Unit test: [specific test case, e.g., "returns error when input empty"]
- [ ] Integration test: [e.g., "API endpoint returns created resource"]
- [ ] Typecheck passes
- [ ] All tests pass

**Integrates with:** [other stories this connects to]
**Depends on:** [stories that must be completed first]
```

**Test requirement granularity:** Include specific test cases directly in acceptance criteria. Be as specific as possible. Name concrete test cases where you can identify them. Where it's unclear, describe the category (e.g., "Unit tests for validation logic").

---

## Story Rules

### Rule 1: Test Harness First
US-001 is always test infrastructure setup. No feature work until tests are runnable.

### Rule 2: All Tests Pass = Commit Gate
Every story includes "All tests pass" in acceptance criteria. Ralph cannot complete a story unless the full test suite passes.

### Rule 3: Validation Checkpoints
When you have repetitive stories (3+ similar items):

1. **First instance** - Build the pattern with tests
2. **Validation checkpoint** - Verify pattern works end-to-end
3. **Remaining instances** - Replicate the validated pattern

```markdown
### US-005: Create first API endpoint (users)
[Full implementation with tests]

### US-006: CHECKPOINT - Validate API pattern
**Acceptance Criteria:**
- [ ] Call endpoint from real client (not just unit test)
- [ ] Verify request/response cycle works
- [ ] All tests pass
- [ ] **STOP if this fails** - fix pattern before proceeding

### US-007: Create remaining API endpoints
[Now safe to replicate]
```

### Rule 4: No "Assume Available"
Never assume external integrations are configured. Either:
- Include configuration as a story, OR
- List as explicit prerequisite with verification command

### Rule 5: Dependencies Explicit
State dependencies clearly:
```markdown
**Depends on:** US-003 (database schema)
**Integrates with:** US-005 (API), US-008 (UI)
```

---

## prd.json Format

```json
{
  "project": "[Project Name]",
  "description": "[Feature description]",
  "testCommand": "[e.g., npm test]",
  "userStories": [
    {
      "id": "US-001",
      "title": "Set up test harness",
      "description": "As a developer, I need test infrastructure so all future work is verified before commits.",
      "acceptanceCriteria": [
        "Test framework installed and configured",
        "Unit test setup working (example test passes)",
        "Integration test setup working (example test passes)",
        "Test command documented",
        "Typecheck passes",
        "All tests pass"
      ],
      "passes": false,
      "notes": ""
    },
    {
      "id": "US-002",
      "title": "[Feature title]",
      "description": "As a [user], I want [feature] so that [benefit].",
      "acceptanceCriteria": [
        "Specific verifiable criterion",
        "Another criterion",
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

### JSON Generation Rules

1. **Story sizing** - Each story completable in ONE context window
   - Right: "Add a database column", "Add a UI component"
   - Wrong: "Build entire dashboard", "Add authentication"
   - Rule of thumb: If you can't describe it in 2-3 sentences, split it

2. **Verifiable acceptance criteria** - No vague terms
   - Good: "Button shows confirmation dialog before deleting"
   - Bad: "Works correctly", "Good UX"

3. **Required criteria on every story:**
   - "Typecheck passes" (or equivalent: PHPStan, mypy, go vet, cargo check)
   - "All tests pass"

4. **UI stories additionally require:**
   - "Verify in browser"

5. **Split large features** - Break into focused, independent stories

---

## Output

After completing all phases, generate:

1. `.ralph/PRD.md` - Full PRD document
2. `.ralph/prd.json` - JSON for Ralph execution

Ask the user to review both files before they run Ralph.

---

## Checklist

Before saving:

- [ ] Completed Discovery phase (problem, users, scope, happy path, edge cases)
- [ ] Completed Architecture & Test Strategy phase (tech stack + testing approach)
- [ ] US-001 is test harness setup
- [ ] Every story has "All tests pass" in acceptance criteria
- [ ] Every story has specific test requirements in acceptance criteria (e.g., "Unit test: validates input")
- [ ] UI stories have "Verify in browser"
- [ ] Story dependencies explicit with "Depends on:" and "Integrates with:"
- [ ] No "assume available" for integrations
- [ ] Stories are small enough for one context window
- [ ] Both PRD.md and prd.json generated
