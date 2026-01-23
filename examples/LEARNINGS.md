# Ralph Learnings Database

This document captures structured learnings from Ralph implementations. Reference during PRD creation and analysis.

---

## Failure Mode Categories

| Code | Name | Definition |
|------|------|------------|
| `ARCHITECTURE_MISSING` | No Architecture Explanation | PRD described files/artifacts but not how they connect at runtime. Agent built plausible files that don't integrate. |
| `TESTS_NO_INFRA` | Tests Required Without Infrastructure | Acceptance criteria require tests, but no story sets up test framework. Tests become ignored checkboxes. |
| `ASSUME_AVAILABLE` | Core Functionality Deferred | PRD uses "assume available" to defer essential integrations. Builds infrastructure without capabilities. |
| `CHECKPOINTS_IGNORED` | Validation Without Enforcement | Checkpoint stories say "STOP if fails" but have no enforcement mechanism. Agent continues regardless. |
| `NO_CROSS_REFS` | Missing Cross-References | Dependencies between components not stated at point of use. Consumers must guess correct order. |
| `PATTERN_NOT_VALIDATED` | Pattern Replicated Before Validation | One pattern implemented 20+ times before testing if it works. Wrong pattern deeply entrenched. |

---

## Project Summaries

### marketing-harness-claude-1

- **Outcome:** Failed
- **Stories:** 19/19 passed
- **Failure Mode:** `ASSUME_AVAILABLE`
- **Key Learning:** "Assume available" lets PRDs avoid specifying critical functionality. Result: infrastructure without capabilities.
- **What Happened:** PRD specified task queue, state files, and documentation but deferred MCP integrations to "assume available" non-goals. Built a task management system, not a sales/marketing automation system.

### mcp-woocommerce

- **Outcome:** Partial
- **Stories:** All passed
- **Failure Mode:** `NO_CROSS_REFS`
- **Key Learning:** Dependencies between components must be stated at point of use, not just in overview sections.
- **What Happened:** Tool descriptions didn't state prerequisites (`get_shipping_methods` requires `set_shipping_address` first). Consumers had to infer correct order through trial and error.

### mcp-woocommerce-v5

- **Outcome:** Partial
- **Stories:** 34/34 passed
- **Failure Mode:** `TESTS_NO_INFRA`
- **Key Learning:** PRD testing section with detailed requirements is useless if prd.json has zero test stories.
- **What Happened:** PRD Section 10 specified unit tests, integration tests, security tests, performance tests. prd.json had 34 stories, none about testing. Also had code duplication (prompt.md issue).

### ralph-claude-harness-bbb-1

- **Outcome:** Failed
- **Stories:** 0/40 passed (all marked passing, none actually working)
- **Failure Mode:** `ARCHITECTURE_MISSING`
- **Key Learning:** PRD must explain runtime architecture, not just list deliverables. Agent optimizes for "make criteria pass" without understanding integration.
- **What Happened:** PRD said "build MCP tools" without explaining MCP server architecture. Agent built 27 TypeScript files with types and schemas that nothing uses. No MCP server, no hook registration, no integration.

### ralph-claude-harness-bbb-2

- **Outcome:** Failed
- **Stories:** 42/42 passed
- **Failure Mode:** `CHECKPOINTS_IGNORED`, `TESTS_NO_INFRA`
- **Key Learning:** "STOP if fails" is documentation, not enforcement. Tests require test infrastructure first.
- **What Happened:** v2 PRD added architecture explanations (improvement!), but: (1) "Unit test passes" in 25+ stories without test framework story, (2) Checkpoint stories said "CRITICAL: STOP" but had no enforcement, (3) Hook coverage missed 3 of 8 platforms.

---

## Anti-Patterns (Things That Failed)

### 1. "Assume Available" Escape Hatch
**Pattern:** PRD defers critical functionality with "assume [X] exists" or "assume [X] is configured"
**Why It Fails:** Creates false sense of completeness. Agent builds around the assumption without validating it holds.
**Example:** marketing-harness-claude-1 said "assume MCP tools exist for all integrations" - built task queue that calls tools that don't exist.
**Fix:** Either include integration stories OR list explicit prerequisites with verification commands.

### 2. Tests in PRD, Not in prd.json
**Pattern:** PRD has detailed "Testing Requirements" section, but prd.json has zero test stories.
**Why It Fails:** Agent implements prd.json, not PRD prose. Testing requirements become aspirational documentation.
**Example:** mcp-woocommerce-v5 PRD specified 100% validation coverage, 90% session management coverage, 12 integration scenarios. Zero test stories in prd.json.
**Fix:** Add US-001 "Set up test infrastructure" before any test-requiring stories.

### 3. Checkpoint Without Enforcement
**Pattern:** Story says "CRITICAL: STOP if this fails" but is structurally identical to other stories.
**Why It Fails:** No mechanism enforces the stop. Agent marks it passed and continues.
**Example:** ralph-claude-harness-bbb-2 US-007 "Validation Checkpoint" was marked passed with notes about logging, but no actual validation that Claude completed the task.
**Fix:** Checkpoint stories must have verifiable success criteria (exit code, specific output, file contents).

### 4. Pattern Replication Without Validation
**Pattern:** Implement same pattern for many items (20+ tools, endpoints, etc.) before testing if pattern works.
**Why It Fails:** If pattern is wrong, you have 20+ broken implementations. Rework is massive.
**Example:** ralph-claude-harness-bbb-1 built 27 MCP tool definitions before testing if Claude could use even one. Architecture was fundamentally wrong.
**Fix:** After establishing pattern once, add validation checkpoint before replicating.

### 5. Glossary-Only Domain Concepts
**Pattern:** Domain concepts (e.g., "cart item key", "variable product") explained in appendix, not at point of use.
**Why It Fails:** Readers cross-reference while reading, breaking flow and risking misunderstanding.
**Example:** mcp-woocommerce explained "variable products" in glossary but not in `add_to_cart` description where it matters.
**Fix:** Explain concepts inline where first encountered, use glossary for detailed reference.

### 6. File Structure Over-Specification
**Pattern:** PRD specifies exact file names and locations that don't match platform conventions.
**Why It Fails:** Agent may create unnecessary files, or correct implementation diverges from PRD causing confusion.
**Example:** mcp-woocommerce-v5 specified `class-activator.php` but WordPress best practice is different. File never created.
**Fix:** Specify interfaces and behaviors, not implementation file structure.

---

## Patterns That Worked

### 1. Architecture-First PRD (bbb-2 improvement)
**Pattern:** Before any stories, explain how pieces connect at runtime.
**Why It Works:** Agent understands integration, not just deliverables.
**Example:** bbb-2 PRD included MCP server architecture explanation, hook registration details, prompt requirements.
**Note:** This is necessary but not sufficient - bbb-2 still failed due to other issues.

### 2. Self-Documenting Tool Descriptions (v5 improvement)
**Pattern:** Tool descriptions include: prerequisites at point of use, return value cross-references, inline domain explanations.
**Why It Works:** Consumers can use tools without cross-referencing other sections.
**Example:** mcp-woocommerce-v5 US-032 "Self-documenting tool descriptions" addressed v4 gaps. Tool descriptions in final implementation were comprehensive.

### 3. Verification Commands in Prerequisites
**Pattern:** Instead of "assume X configured", specify "verify with: `command`"
**Why It Works:** Agent can validate assumption before proceeding. Fails early if prerequisite missing.
**Example:** (Proposed, not yet implemented) Instead of "assume MCP tools available", use "verify: `claude /mcp` shows tool list"

### 4. Test Infrastructure as US-001
**Pattern:** First story sets up test framework. Subsequent stories can require tests.
**Why It Works:** Infrastructure exists before it's needed. Tests are real, not ignored.
**Example:** (Proposed, not yet implemented) US-001 "Set up Jest with TypeScript support, verify `npm test` runs"

---

## Quick Reference: PRD Checklist

Before finalizing a PRD, verify:

- [ ] **Architecture explained** - How do pieces connect at runtime? Not just what files to create.
- [ ] **No "assume available"** - Either include integration stories or specify verification commands.
- [ ] **Test infrastructure story exists** - If any story requires tests, US-001 sets up test framework.
- [ ] **Checkpoints have enforcement** - Validation stories have verifiable success criteria, not just "STOP" documentation.
- [ ] **Pattern validated before replication** - After first instance of repeating pattern, add validation before doing 19 more.
- [ ] **Dependencies at point of use** - Each component states its prerequisites, not just overview section.
- [ ] **prd.json matches PRD sections** - Everything in PRD (especially tests) has corresponding stories.
