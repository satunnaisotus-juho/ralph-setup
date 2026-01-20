---
description: "Generate a Product Requirements Document (PRD) for a new feature. Use when planning a feature, starting a new project, or when asked to create a PRD."
---

# PRD Generator v2

Create PRDs that transfer **system understanding**, not just feature lists.

**Key principle:** Gather all intent and details BEFORE making architectural decisions. This ensures technical choices are informed by the full picture.

---

## The Job

A multi-phase conversation that builds understanding progressively:

1. **Phase 1: Intent** - Understand the problem and goals deeply
2. **Phase 2: User Journey** - Map how users interact with the system
3. **Phase 3: Details & Edge Cases** - Explore specifics and boundaries
4. **Phase 4: Architecture** - NOW make technical decisions (with full context)
5. **Phase 5: Generate PRD** - Write the document with stories

**Important:** Do NOT start implementing. Just create the PRD.

---

## Phase 1: Intent (The "Why")

Start by understanding the core intent. Ask questions like:

```
1. What problem are we solving?
   A. [Inferred option based on their description]
   B. [Alternative interpretation]
   C. [Another angle]
   D. Other: [please specify]

2. Who experiences this problem most acutely?
   A. [User type 1]
   B. [User type 2]
   C. [User type 3]
   D. Other: [please specify]

3. What does success look like for the user?
   A. They can do X faster
   B. They can do Y that was impossible before
   C. They avoid pain point Z
   D. Other: [please specify]

4. What's the scope?
   A. Minimal - just solve the core problem
   B. Complete - full-featured solution
   C. Foundation - build for future expansion
   D. Other: [please specify]
```

**Goal:** Understand WHY this matters before discussing WHAT to build.

---

## Phase 2: User Journey (The "How Users See It")

Now map the user's experience. Ask questions like:

```
5. Walk me through the user's journey. What triggers them to use this?
   A. [Scenario 1]
   B. [Scenario 2]
   C. Multiple entry points
   D. Other: [please specify]

6. What's the happy path - the ideal flow from start to finish?
   [Ask them to describe step by step]

7. What are the key decision points or branches in the flow?
   [Explore alternatives and variations]

8. What feedback does the user need at each step?
   A. Visual confirmation
   B. Data/results display
   C. Progress indication
   D. Error messages only
```

**Goal:** Build a mental model of user interaction BEFORE thinking about implementation.

---

## Phase 3: Details & Edge Cases (The "What Ifs")

Explore the specifics and boundaries:

```
9. What happens when things go wrong?
   - What errors can occur?
   - How should the system respond?
   - What does the user see?

10. What are the boundaries?
    - What should this NOT do? (critical for scope)
    - What's explicitly out of scope for now?

11. Are there any constraints I should know about?
    - Existing systems to integrate with?
    - Performance requirements?
    - Security considerations?

12. What terms or concepts are specific to this domain?
    [Build a glossary of domain language]
```

**Goal:** Surface hidden requirements and implicit assumptions.

---

## Phase 4: Architecture (The "How It Works")

NOW, with full context, discuss technical approach:

```
13. Based on everything above, here's how I understand the system working:
    [Describe the execution model / how pieces connect]

    Does this match your mental model?

14. I see these as the main components:
    - [Component A]: does X
    - [Component B]: does Y
    - [Component C]: connects A to B

    Does this breakdown make sense?

15. For technical approach, I'm thinking:
    A. [Approach 1 with tradeoffs]
    B. [Approach 2 with tradeoffs]
    C. [Approach 3 with tradeoffs]

    Which aligns best with your constraints?
```

**Goal:** Confirm the mental model and technical approach BEFORE writing stories.

---

## Phase 5: Generate PRD

Now write the PRD with these sections:

### PRD Structure

```markdown
# PRD: [Feature Name]

## 1. Problem Statement
What problem are we solving and why it matters.
[From Phase 1]

## 2. Goals
Specific, measurable objectives.
[From Phase 1]

## 3. User Journey
Step-by-step flow from the user's perspective.
[From Phase 2 - this is the mental model transfer]

## 4. How It Works
**This section is critical.** Explain the execution model:
- How do the pieces connect at runtime?
- What calls what?
- What's the data flow?

Include a simple diagram if helpful:
```
User action → Component A → Component B → Result
                  ↓
            Component C (async)
```

[From Phase 4]

## 5. Key Concepts
Domain-specific terms explained where they matter.
[From Phase 3]

## 6. User Stories
[See story format below]

## 7. Non-Goals
What this explicitly does NOT include.
[From Phase 3]

## 8. Open Questions
Remaining uncertainties.
```

---

## User Story Format

### Story Structure

```markdown
### US-001: [Title]
**Description:** As a [user], I want [feature] so that [benefit].

**Acceptance Criteria:**
- [ ] [Specific verifiable criterion]
- [ ] [Another criterion]
- [ ] Typecheck/lint passes
- [ ] [Integration criterion - how this connects to other parts]

**Integrates with:** [List other stories/components this connects to]
```

### Story Rules

#### Rule 1: Infrastructure Before Features
If the system needs a foundation (server, database schema, core module), that's the FIRST story.

**Wrong order:**
- US-001: Add feature to server
- US-002: Add another feature to server
- US-003: Create server ← too late!

**Right order:**
- US-001: Create server foundation
- US-002: Add first feature
- US-003: Add second feature

#### Rule 2: Validation Checkpoints After First Instance

When you have repetitive stories (3+ similar items), structure them as:

1. **First instance** - Build the pattern
2. **Validation checkpoint** - Verify pattern works end-to-end
3. **Remaining instances** - Replicate the validated pattern

**Example:**
```markdown
### US-005: Create first API endpoint (users)
[Full implementation of the pattern]

### US-006: CHECKPOINT - Validate API pattern works
**Description:** Verify the API pattern works end-to-end before building more endpoints.

**Acceptance Criteria:**
- [ ] Call endpoint from real client (not just unit test)
- [ ] Verify request/response cycle works
- [ ] Confirm error handling works as expected
- [ ] **STOP if this fails** - fix pattern before proceeding

### US-007: Create remaining API endpoints
[Now safe to replicate the pattern]
```

#### Rule 3: Integration Criteria, Not Just Local Criteria

Every story should include at least one criterion that validates integration:

**Local only (insufficient):**
- [ ] Function returns correct value
- [ ] Unit test passes

**With integration (better):**
- [ ] Function returns correct value
- [ ] Unit test passes
- [ ] Function is called by [Component X] in production flow
- [ ] End-to-end: User action triggers this and produces expected result

#### Rule 4: Precise Language

Avoid ambiguous terms. Be specific:

| Ambiguous | Precise |
|-----------|---------|
| "Test that X works" | "Unit test: call X directly, verify output" |
| "Test that X works" | "Integration test: trigger X via user action, verify result" |
| "Component Y" | "Y module (file: src/y.ts)" |
| "Component Y" | "Y service (runs as separate process)" |
| "Integrates with Z" | "Calls Z's API endpoint /foo" |
| "Integrates with Z" | "Z calls this via event handler" |

#### Rule 5: Prerequisites at Point of Use

If a story depends on another, state it explicitly:

```markdown
### US-008: Add payment processing
**Depends on:** US-003 (database schema), US-005 (API foundation)

**Acceptance Criteria:**
- [ ] Requires: Cart total available from US-007
- [ ] Produces: Payment confirmation used by US-010
```

---

## Example PRD (v2 Format)

```markdown
# PRD: Task Priority System

## 1. Problem Statement

Users have many tasks but no way to indicate which ones matter most. They waste time scanning the full list to find urgent items. We need priority levels so users can focus on what's important.

## 2. Goals

- Users can mark tasks as high/medium/low priority
- High-priority tasks are visually prominent
- Users can filter to see only high-priority items
- Priority persists across sessions

## 3. User Journey

1. User creates a task → defaults to medium priority
2. User realizes task is urgent → clicks priority indicator → selects "high"
3. Task card updates to show red priority badge
4. Later, user wants to focus → clicks filter → selects "high priority only"
5. List shows only high-priority tasks

## 4. How It Works

```
User clicks priority → UI calls updateTask API → Database updates → UI reflects change
                                                        ↓
User clicks filter → URL params update → Query filters by priority → List re-renders
```

**Data flow:**
- Priority stored in `tasks.priority` column (enum: high/medium/low)
- Filter state stored in URL params (`?priority=high`)
- No computed priority - always explicit user choice

## 5. Key Concepts

- **Priority levels:** high (red), medium (yellow), low (gray) - visual color coding
- **Default priority:** new tasks start as medium (not high, to avoid alert fatigue)

## 6. User Stories

### US-001: Add priority column to database
**Description:** As a developer, I need to store task priority so it persists across sessions.

**Acceptance Criteria:**
- [ ] Add priority column: enum('high', 'medium', 'low') default 'medium'
- [ ] Migration runs successfully
- [ ] Existing tasks get 'medium' priority
- [ ] Typecheck passes
- [ ] **Integration:** API can read/write priority field (verified in US-002)

**Integrates with:** US-002 (API), US-003 (UI display)

---

### US-002: CHECKPOINT - API can read/write priority
**Description:** Verify the data layer works before building UI.

**Acceptance Criteria:**
- [ ] GET /tasks returns priority field
- [ ] PATCH /tasks/:id accepts priority update
- [ ] Invalid priority value returns 400 error
- [ ] Typecheck passes
- [ ] **STOP if this fails** - fix data layer before building UI

**Integrates with:** US-001 (database), US-003 (UI)

---

### US-003: Display priority badge on task cards
**Description:** As a user, I want to see task priority at a glance.

**Acceptance Criteria:**
- [ ] Task card shows colored badge (red=high, yellow=medium, gray=low)
- [ ] Badge visible without hover/click
- [ ] Typecheck passes
- [ ] Verify in browser
- [ ] **Integration:** Badge updates when priority changes via US-004

**Integrates with:** US-002 (reads priority), US-004 (updates priority)

---

### US-004: Priority selector in task edit
**Description:** As a user, I want to change task priority.

**Acceptance Criteria:**
- [ ] Dropdown in task edit modal with high/medium/low options
- [ ] Current priority shown as selected
- [ ] Selection calls API and updates badge immediately
- [ ] Typecheck passes
- [ ] Verify in browser
- [ ] **Integration:** Changing priority updates filter results in US-005

**Integrates with:** US-002 (API), US-003 (badge display), US-005 (filter)

---

### US-005: Filter tasks by priority
**Description:** As a user, I want to see only high-priority tasks when focusing.

**Acceptance Criteria:**
- [ ] Filter dropdown: All | High | Medium | Low
- [ ] Filter stored in URL params (?priority=high)
- [ ] Empty state when no tasks match
- [ ] Typecheck passes
- [ ] Verify in browser
- [ ] **Integration:** End-to-end test: create task → set high priority → filter → task appears

**Integrates with:** US-001 (data), US-004 (priority changes)

## 7. Non-Goals

- No priority-based notifications
- No automatic priority based on due date
- No priority inheritance for subtasks
- No keyboard shortcuts (future enhancement)

## 8. Open Questions

- Should priority affect sort order within columns?
```

---

## Checklist

Before saving the PRD:

- [ ] Completed all 4 phases of questions (Intent → Journey → Details → Architecture)
- [ ] "How It Works" section explains the execution model clearly
- [ ] Infrastructure stories come before feature stories
- [ ] Validation checkpoints after first instance of repetitive patterns
- [ ] Each story has integration criteria (not just local criteria)
- [ ] Ambiguous terms replaced with precise language
- [ ] Dependencies explicitly stated with "Depends on:" and "Integrates with:"
- [ ] Non-goals clearly define what's out of scope
- [ ] Saved to `PRD.md`
