# Plan: Create PRD for Sales & Marketing Task Harness

## Goal

Create a `PRD.md` file that defines the requirements for a sales & marketing task executor system. Ralph will then use this PRD to implement the system.

## Important: Separation of Concerns

This project is being built **within a Ralph loop**. The deliverables must be kept separate from the builder Ralph:

- **Root level**: Existing Ralph loop (builds this project) - `ralph.sh`, `prompt.md`, `prd.json`
- **`src/`**: All marketing/sales agent deliverables - its own ralph loop, prompt, MCP tools, Claude artifacts, mocks

This ensures the marketing agent system is self-contained and doesn't conflict with the Ralph that builds it.

## PRD Structure

The PRD.md will include:

### 1. Project Overview
- Purpose: Continuous task executor for sales/marketing tasks, running Claude in a loop
- Key behavior: Loop runs Claude with a prompt, Claude processes one task per iteration using the project's tools/skills/commands/hooks, sleeps when queue is empty
- Core deliverable: Implement Claude Code skills, commands, hooks, and MCP tools that Claude uses during task execution
- Integration points: MCP tools (including Matrix), Claude Code hooks/commands/skills

### 2. Core Concepts
- **Task queue** (`src/tasks.json`): List of tasks with status/priority. Tasks reflect **activities a human might do** - they can be complex, multi-step instructions that Claude interprets and executes autonomously, not just simple tool calls. Claude can create other complex task patterns as needed.
- **Complex task example**: "Check the 5 best performing GM posts from Instagram. Pick one randomly and use it as inspiration to create and post today's GM post. Schedule next morning's GM post."
- **Feedback-Activity-Repeat pattern**: Tasks often involve getting feedback/analytics → performing activities based on feedback → scheduling repeating activities
- **Continuous loop** (`src/ralph.sh`): Runs Claude with a prompt in a loop. Processes one task per iteration, sleeps when queue is empty. Claude uses the project's skills, commands, hooks, and MCP tools.
- **Claude Code integration**: The project implements skills, commands, hooks, and MCP tools in `src/` that Claude uses when executing tasks. This is a key purpose of the project.
- **Context files**: Brand voice, ICP, templates in `src/context/` that inform task execution

### 3. User Stories

Stories will cover these areas:

**Foundation** (all in `src/`)
- Directory structure setup under `src/`
- `src/tasks.json` schema definition
- Continuous polling loop (`src/ralph.sh`)
- Marketing agent prompt (`src/marketing-prompt.md`)

**MCP Tools** (`src/mcp/`) - covering all marketing/sales activities:

*CRM & Lead Management*
- CRM tools (lead_create, lead_update, lead_search, lead_tag)

*Email & Outreach*
- Cold email (send_email, schedule_sequence)
- Mailchimp (create_campaign, add_subscriber, send_campaign, get_stats)
- Mailing list management (create_list, segment_audience)

*Social Media Marketing*
- X/Twitter (post, reply, dm, get_engagement)
- LinkedIn (post, connect, message, get_insights)
- Instagram (post, story, reel, get_insights)
- Nostr (publish_note, get_replies)
- Facebook (post, ad_create, get_insights)
- YouTube (upload, get_analytics)
- TikTok (post, get_analytics)
- Bluesky (post, get_engagement)

*Paid Ads Marketing*
- Google Ads (create_campaign, set_budget, get_performance)
- Facebook/Meta Ads (create_ad, target_audience, get_results)
- LinkedIn Ads (create_campaign, get_analytics)

*Website Content Management*
- CMS tools (create_page, update_content, publish)
- Blog tools (create_post, schedule_post)
- Landing page tools (create_landing_page, a_b_test)

*Human Feedback*
- Matrix tools (send_message, get_messages)

*Analytics & Performance Measurement*
- Google Analytics (traffic, conversions, campaign performance)
- Social platform metrics (engagement, reach, followers)
- WooCommerce (sales, orders, revenue)
- Email stats (opens, clicks, bounces, conversions)
- Ad performance (ROAS, CPC, CTR)

**Mock System** (`src/mocks/`)
- API-level tool interceptor for testing
- Mock handlers for MCP tools
- Mock handlers for Claude built-in tools (bash, read, write)
- Hook simulation (pre-send blocking)
- Test harness combining all mocks

**Claude Code Artifacts** (`src/.claude/`) - key deliverable, Claude uses these
- `/task-add` command - Claude invokes to add tasks
- `/task-status` command - Claude invokes to view queue
- `pre-send` hook - runs before outbound actions, can block
- Skills for common task patterns

**Feedback** (via Matrix MCP tools)
- Read messages from Matrix channel
- Create feedback tasks from human messages
- Confirm task completion via Matrix

### 4. User Story Format

Each user story will include:
- Clear description of what needs to be built
- Dependencies on other stories (if any)
- Acceptance criteria as checkboxes:
  - Functional requirements
  - **Test with mocked environment**: Run `claude` with mock tools/hooks and verify expected behavior (e.g., "Claude calls `mcp__email__send_email` with correct params when processing an email task")

## Files to Create

| File | Purpose |
|------|---------|
| `PRD-PLAN.md` | This plan document (for reference) |
| `PRD.md` | Main requirements document |

## Verification

After creating PRD.md:
1. Run `/ralph-prd-to-json` to generate `prd.json`
2. Verify `prd.json` has valid user stories with `passes: false`
3. Ralph can then process the stories iteratively

**Story verification approach**: Each story's acceptance criteria will include running `claude` with the mocked environment and asserting Claude exhibits expected behavior (correct tool calls, proper hook triggers, etc.)
