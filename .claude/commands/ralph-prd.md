---
description: "Generate a Product Requirements Document (PRD) for a new feature. Use when planning a feature, starting a new project, or when asked to create a PRD."
---

# PRD Generator v3 (Test-Focused)

Create PRDs that prioritize **testability** from the start. Every project begins with test infrastructure, and every story includes test requirements.

**Key principle:** Test harness first, features second. All stories must pass the test suite before completion.

---

## The Job

A 4-phase conversation:

1. **Phase 1: Discovery** - Understand the problem, users, scope, and edge cases
2. **Phase 2: Reference Implementation Search** - Find and analyze GitHub repos for patterns
3. **Phase 3: Architecture & Test Strategy** - Tech stack AND testing approach together
4. **Phase 4: Generate PRD** - Write PRD.md and prd.json with test-first stories

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
- **External integrations**: What external services/APIs does this need?
  - For EACH external service: Get the exact interface (see Rule 7)
  - If user says "assume available" → require interface spec before proceeding
  - List: service name, required methods/endpoints, expected response types
- **System requirements:** Does this need sudo? Network access? Special hardware? Long-running operations (>10 min)?
- **Distribution method:** How will users get this? (package registry, container registry, build from source, binary releases?)
- **Distribution during project:** Will this be published during the project scope, or is it source-only for now?

**Quick codebase check:** If the directory has existing code, briefly scan for existing test infrastructure before proceeding.

**Goal:** Build a complete mental model before discussing implementation.

---

## Phase 2: Reference Implementation Search

Before architecture decisions, find real-world implementations to learn from.

### 1. Search GitHub for References

```bash
gh search repos "[project-type] [tech-stack]" --limit 10 --json name,url,stargazersCount,updatedAt,description
```

Select 4-5 most relevant based on:
- Stars > 50 (prefer > 500 for maturity)
- Updated within 6 months
- Appropriate license (MIT, Apache, BSD)
- Relevant to project goals

### 2. Clone to Temporary Directory

```bash
mkdir -p /tmp/ralph-refs-{project-name}
git clone --depth 1 {repo-url} /tmp/ralph-refs-{project-name}/{repo-name}
```

### 3. Comprehensive Security Analysis

**Phase A: Reputation Check**
- Stars > 50 (prefer > 500)
- Multiple contributors (not single-author)
- Recent activity (commits in last 6 months)
- Has security policy (SECURITY.md)
- Known organization or verified maintainer

**Phase B: Dependency Scan**
```bash
# Check for known vulnerabilities (run in cloned repo)
npm audit --json 2>/dev/null || pip-audit --format json 2>/dev/null || true
```

**Phase C: Static Code Analysis**

Automatic rejection (remove repo):
- Base64/hex-encoded strings in source (except test fixtures, assets)
- Binary blobs without corresponding source
- postinstall/preinstall hooks that download or execute
- References to sensitive paths: ~/.ssh, ~/.aws, ~/.gnupg, /etc/passwd
- Hardcoded IPs/domains with outbound connections
- Obfuscated/minified code without source maps
- Environment variable exfiltration patterns

**Phase D: Code Flow Analysis**

Examine for dangerous patterns:
- eval(), exec(), Function() constructor usage
- child_process.exec/spawn, subprocess.run
- Dynamic require/import from user input
- Prototype pollution patterns
- SQL/command injection vectors
- Deserialization of untrusted data

Document context if found (may be legitimate):
- Network calls: document purpose and endpoints
- File system access: document what files and why
- Process spawning: document what commands

**Phase E: Install Script Audit**
- Review package.json scripts (postinstall, preinstall, prepare)
- Check setup.py/pyproject.toml for install hooks
- Verify Makefile targets don't execute unexpected code

### 4. Analyze Best 2-3 Repos

For each selected repo, document:
- Purpose and relevance to this project
- Key architectural patterns worth adopting
- Useful code files to reference during implementation
- Caveats or limitations

### 5. Use Findings

The reference implementations inform Phase 3 (Architecture):
- Validate or challenge proposed tech stack
- Identify proven patterns to adopt
- Note anti-patterns to avoid
- Reference specific files for implementation guidance

---

## Phase 3: Architecture & Test Strategy

Tech decisions and testing decisions inform each other - make them together.
**Use reference implementations from Phase 2 to validate architectural choices.**

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

### Reference Validation
- Which patterns from reference repos should we adopt?
- What approaches should we avoid (learned from references)?
- Specific files to reference during implementation

**Goal:** Clear technical approach AND clear testing approach before writing stories.

---

## Phase 4: Generate PRD

Write two files:
1. `.ralph/PRD.md` - Human-readable documentation
2. `.ralph/prd.json` - Machine-readable for Ralph execution

### PRD.md Structure

```markdown
# PRD: [Feature Name]

## 1. Problem Statement
What problem are we solving and why it matters.

## 2. Prerequisites
System requirements and permissions needed. **Declare upfront, not when blocked.**

- **Permissions:** [e.g., sudo required for package installation]
- **Network:** [e.g., internet access for API calls]
- **Hardware:** [e.g., microphone for voice features]
- **Long-running ops:** [e.g., ISO build takes ~30 min - use background execution]
- **Distribution:** [e.g., "Source-only (not published)" or "Published to {registry} as {package-name}"]

Verification commands (run before starting):
```bash
# Example: verify sudo access
sudo -n true && echo "sudo OK" || echo "sudo MISSING"
```

## 3. Goals
Specific, measurable objectives (bullet list).

## 4. How It Works
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

## 5. Test Strategy
- **Test framework:** [framework name]
- **Test command:** `[e.g., npm test]`
- **Unit tests:** [what they cover]
- **Integration tests:** [what they cover]
- **E2E tests:** [what they cover, if applicable]

## 6. User Stories
[See story format below]

## 7. Non-Goals
What this explicitly does NOT include.

## 8. Open Questions
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

### Rule 6: Fresh Clone Test
Documentation stories (README, installation guides) must validate that documented paths actually work:

- **Always required:** "Fresh clone test: clone repo to new directory, follow README exactly, verify it works"
- **If NOT published:** README MUST include "Building from Source" section. Config examples use local paths, not package names.
- **If published:** Only document published installation AFTER the publish/release story completes

Example for unpublished project:
```markdown
### US-026: CLI and README
**Acceptance Criteria:**
- [ ] README includes "Building from Source" section with exact commands
- [ ] README states distribution status (e.g., "Not yet published to npm")
- [ ] Config examples use local paths that work after build
- [ ] Fresh clone test: clone to clean directory, follow README, verify it works
- [ ] All tests pass
```

### Rule 7: External Dependency Interface Contracts

If a PRD references ANY external service, you MUST get the exact interface:

**During Discovery, for each external dependency:**
1. Ask: "What is the exact interface?" (methods, types, endpoints)
2. If user says "assume it exists" → REFUSE until they provide the spec
3. Document the interface in PRD prerequisites

**PRD Format:**
```markdown
## External Dependencies

### [Service Name]
**Required for:** US-XXX, US-YYY
**Interface Contract:**
```
// Data types (language-agnostic)
ServiceResponse:
  - field1: string
  - field2: number
  - items: list of ItemType

// Methods or endpoints
method_name(param: string) -> ServiceResponse
  - Description of what it does
  - Error cases: [list error conditions]

// For HTTP services:
GET /endpoint
  Request: { query_param: type }
  Response: { field: type }
  Errors: 404 if not found, 401 if unauthorized
```
**Mock story:** US-XXX creates mock implementing this interface
**Verify real:** Health check command or equivalent
```

**Story requirement:** The FIRST story using an external dep MUST:
- Create a mock/stub implementing the interface
- Include acceptance criterion: "Mock [service] created and tests use it"

**No hand-waving.** Every external dep needs a mockable contract before any dependent stories.

### Rule 8: Application Startup Story

Every PRD MUST include a story validating the application builds and starts.

**Place this story:** After core implementation, before final integration test.

**Template:**
```markdown
### US-0XX: Build and run application successfully
**Acceptance Criteria:**
- [ ] Build command completes without errors (`npm run build`, `go build`, `cargo build`, etc.)
- [ ] Application starts without immediate crash
- [ ] Basic functionality responds (health check, --version, or equivalent)
- [ ] Application stops gracefully (SIGTERM handled)
- [ ] All tests pass
```

**For different project types:**
- **Web servers:** Health endpoint returns 200
- **CLI tools:** `--help` or `--version` exits 0
- **Libraries:** Build succeeds and exports work
- **Scripts:** Main entry runs without import errors

This catches packaging issues (missing assets, wrong paths, missing scripts) early.

---

## prd.json Format

```json
{
  "project": "[Project Name]",
  "description": "[Feature description]",
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

After completing all phases, generate four files:

1. `.ralph/PRD.md` - Full PRD document
2. `.ralph/prd.json` - JSON for Ralph execution
3. `.ralph/initiation-chat.md` - Record of the discovery conversation
4. `.ralph/reference-implementations.md` - Reference repos for implementation guidance

### initiation-chat.md Format

Capture the conversation that led to this PRD:

```markdown
# Initiation Chat

**Date:** [YYYY-MM-DD]
**Feature:** [Feature name]

---

## Original Request

[What the user initially asked for - their first message or description]

---

## Discovery (Phase 1)

### Problem & Goals
- [Key points discussed]

### Users
- [Who this is for]

### Scope Decisions
- [What's in]
- [What's explicitly out]

### Happy Path
[The ideal user flow as discussed]

### Edge Cases & Error Handling
- [What can go wrong]
- [How errors should be handled]

---

## Reference Implementations (Phase 2)

### Repos Analyzed
- [Repo 1]: [Why selected, key patterns found]
- [Repo 2]: [Why selected, key patterns found]

### Security Analysis
- [Summary of security checks performed]

---

## Architecture Decisions (Phase 3)

### Tech Stack
- [Framework, language, database choices and WHY]

### Test Strategy
- [Testing approach chosen and WHY]

### Reference Validation
- [Which patterns adopted from reference repos]
- [What approaches avoided based on references]

### Key Design Decisions
- [Decision 1]: [Rationale]
- [Decision 2]: [Rationale]

---

## Open Questions Resolved
- Q: [Question raised during discussion]
- A: [How it was resolved]

---

## Notes
[Any other context that would help understand why the PRD looks the way it does]
```

**Why capture this:** When analyzing failed runs, the initiation chat shows whether the problem was in requirements gathering or in PRD generation. It's the "why" behind the PRD.

### reference-implementations.md Format

```markdown
# Reference Implementations

Analyzed: {date}
Project: {project name}

## Selected References

### 1. {repo-name}
**URL:** {github-url}
**Stars:** {count} | **Updated:** {date}
**Security:** PASSED

**Purpose:** {what this repo does, why it's relevant}

**Key Patterns:**
- {pattern with file path reference, e.g., "Auth middleware at src/middleware/auth.ts"}
- {another pattern}

**Useful Files:**
- `path/to/file.ts` - {what it demonstrates}
- `path/to/other.ts` - {what to reference}

**Caveats:**
- {limitations or things to adapt}

---

### 2. {next repo}
...

---

## Security Analysis Summary

**Selected repos:** All passed comprehensive security audit
**Skipped repos:** {list with reasons}

Analysis included:
- Reputation check (stars, contributors, activity)
- Dependency vulnerability scan
- Static code analysis
- Code flow analysis
- Install script audit

## Local Cache

Repos cached at: `/tmp/ralph-refs-{project}/`
Re-clone from URLs above if missing.
```

Ask the user to review all four files before they run Ralph.

---

## Checklist

Before saving:

- [ ] Completed Discovery phase (problem, users, scope, happy path, edge cases, **system requirements**)
- [ ] Completed Reference Implementation Search (4-5 repos searched, 2-3 selected, security verified)
- [ ] Completed Architecture & Test Strategy phase (tech stack + testing approach, validated against references)
- [ ] Prerequisites section lists all permissions (sudo, network, hardware) with verification commands
- [ ] Long-running operations (>10 min) identified and noted in Prerequisites
- [ ] US-001 is test harness setup
- [ ] Every story has "All tests pass" in acceptance criteria
- [ ] Every story has specific test requirements in acceptance criteria (e.g., "Unit test: validates input")
- [ ] UI stories have "Verify in browser"
- [ ] Story dependencies explicit with "Depends on:" and "Integrates with:"
- [ ] No "assume available" for integrations
- [ ] Stories are small enough for one context window
- [ ] PRD.md generated
- [ ] prd.json generated
- [ ] initiation-chat.md generated (captures discovery conversation)
- [ ] reference-implementations.md generated (repos analyzed and documented)
- [ ] Distribution method documented in Prerequisites
- [ ] If source-only: README has "Building from Source", no registry-dependent install commands
- [ ] Documentation stories include "Fresh clone test" acceptance criterion
