# Sales & Marketing Task Harness - PRD

## Project Overview

### Purpose
A continuous task executor for sales and marketing activities, running Claude in a loop. Claude processes tasks from a frequently-updated queue using MCP tools, Claude Code commands/hooks/skills, and context files.

### Key Behavior
- Loop runs Claude with a prompt, processing one task per iteration
- Tasks reflect **activities a human might do** - complex, multi-step instructions Claude interprets autonomously
- When queue is empty, loop sleeps and polls for new tasks
- **Feedback-Activity-Repeat pattern**: Get feedback/analytics → perform activities → schedule repeating activities

### Complex Task Example
> "Check the 5 best performing GM posts from Instagram. Pick one randomly and use it as inspiration to create and post today's GM post. Schedule next morning's GM post."

### Core Deliverables
- Claude Code skills, commands, hooks that Claude uses during task execution
- MCP tools for all marketing/sales activities
- Mock system for testing Claude's behavior
- Continuous task execution loop

### Separation of Concerns
All deliverables live in `src/` to stay separate from the builder Ralph at root level.

---

## User Stories

### Foundation

#### US-001: Directory Structure Setup
**Description**: Set up the directory structure and TypeScript project for the marketing/sales agent under `src/`.

**Acceptance Criteria**:
- [ ] `src/` directory exists with subdirectories: `mcp/`, `mocks/`, `.claude/`, `context/`
- [ ] `src/context/` has subdirectories: `brand/`, `product/`, `audience/`, `templates/`
- [ ] `src/mocks/` has subdirectories: `handlers/`, `fixtures/`
- [ ] `src/.claude/` has subdirectories: `commands/`, `hooks/`
- [ ] Placeholder .gitkeep files exist in each directory to establish structure
- [ ] `src/package.json` exists with TypeScript dependencies (typescript, @types/node)
- [ ] `src/tsconfig.json` exists with strict mode enabled
- [ ] `npm install` succeeds in src/ directory
- [ ] `npx tsc --noEmit` passes (typecheck)

---

#### US-002: Task Queue Schema
**Description**: Define the `tasks.json` schema for the task queue.

**Dependencies**: US-001

**Acceptance Criteria**:
- [ ] `src/tasks.json` exists with valid JSON structure
- [ ] Schema supports: id, description (complex instruction), priority, status, created, completedAt
- [ ] Status values: `pending`, `in_progress`, `completed`, `failed`
- [ ] Priority values: `urgent`, `high`, `normal`, `low`
- [ ] Example tasks demonstrate complex, human-like activities

---

#### US-003: Continuous Polling Loop
**Description**: Implement `src/wiggum.sh` that runs Claude in a continuous loop, processing tasks and sleeping when empty.

**Dependencies**: US-002

**Acceptance Criteria**:
- [ ] `src/wiggum.sh` exists and is executable
- [ ] Loop checks for pending tasks in `src/tasks.json`
- [ ] When pending tasks exist, runs Claude with `src/marketing-prompt.md`
- [ ] When no pending tasks, sleeps for configurable poll interval (default 60s)
- [ ] Loop continues indefinitely until manually stopped
- [ ] Logs iteration status to console
- [ ] Streams Claude output to JSON log file (append-only, following ralph.sh conventions) for human observation via prettifier
- [ ] Supports `--test` flag to run against mock MCP server instead of production

---

#### US-004: Marketing Agent Prompt
**Description**: Create `src/marketing-prompt.md` that instructs Claude how to process tasks.

**Dependencies**: US-002

**Acceptance Criteria**:
- [ ] `src/marketing-prompt.md` exists with clear instructions
- [ ] Instructs Claude to read `tasks.json` and pick highest priority pending task
- [ ] Instructs Claude to read context files for brand voice, ICP, templates
- [ ] Instructs Claude to read `src/context/playbook.md` before starting task for learned strategies
- [ ] Instructs Claude to execute the task using available MCP tools
- [ ] Instructs Claude to update task status to completed/failed
- [ ] Instructs Claude to reflect after task completion: update playbook only for significant, repeated insights (be picky to avoid context pollution)
- [ ] Instructs Claude to create new commands in `src/.claude/commands/` only for patterns seen 2-3+ times successfully
- [ ] Instructs Claude to STOP after completing one task
- [ ] References feedback-activity-repeat pattern for complex tasks

---

### Mock System

#### US-005: MCP Tool Interceptor
**Description**: Create mock interceptor for custom MCP tools that runs as a mock MCP server in test mode.

**Dependencies**: US-001

**Acceptance Criteria**:
- [ ] `src/mocks/interceptor.ts` exists with `MockToolInterceptor` class
- [ ] Runs as mock MCP server when `wiggum.sh --test` is used
- [ ] Interceptor records all MCP tool calls (id, name, input, timestamp)
- [ ] Interceptor routes to registered handlers by tool name
- [ ] Test utilities: `getCalls()`, `getCallsByName()`, `clear()`
- [ ] Same task JSON works in both test and production modes
- [ ] **Mock test**: Interceptor records `lead_create` call and returns mock response

---

#### US-005b: Claude Internal Tool Hooks
**Description**: Hook-based interception for Claude's built-in tools (Read, Bash, Write, Edit) in test mode.

**Dependencies**: US-005

**Acceptance Criteria**:
- [ ] `src/.claude/hooks/` contains pre-tool hooks for internal tools
- [ ] Hooks detect test mode via environment variable (e.g., `WIGGUM_TEST_MODE`)
- [ ] Read/Write routed to test fixtures when accessing mocked paths
- [ ] Bash: allows web access (curl, wget) for research, blocks destructive commands
- [ ] Edit follows same rules as Write
- [ ] Hook records intercepted calls for test assertions
- [ ] **Mock test**: Bash hook allows `curl` for research, blocks `rm -rf`

---

#### US-006: Mock Hook Runner
**Description**: Create programmatic hook simulation for tests, allowing test code to configure hook behavior (allow/block) without relying on actual hook logic.

**Dependencies**: US-005

**Acceptance Criteria**:
- [ ] `src/mocks/hooks.ts` exists with `MockHookRunner` class
- [ ] Hooks can be programmatically configured to allow or block with custom message
- [ ] Hook triggers defined per tool (e.g., `pre-send` triggers for email/social tools)
- [ ] Records all hook invocations for test assertions
- [ ] Allows testing Claude's reaction to blocks independent of actual hook logic
- [ ] **Mock test**: Configure `pre-send` hook to block, verify email tool blocked with message and Claude handles gracefully

---

#### US-007: Test Harness
**Description**: Create `createTestHarness()` that combines interceptor and hooks for full test setup, supporting both unit and integration testing.

**Dependencies**: US-005, US-005b, US-006

**Acceptance Criteria**:
- [ ] `src/mocks/harness.ts` exists with `createTestHarness()` function
- [ ] Returns combined interceptor + hooks + filesystem state
- [ ] `executeToolCall()` method checks hooks before routing to interceptor
- [ ] `simulateToolCall()` for unit testing handler logic directly (fast, no Claude)
- [ ] `runTask()` for integration testing with actual Claude invocation (slower, full behavior)
- [ ] Provides utilities to set up initial filesystem state (fixtures)
- [ ] **Mock test (unit)**: `simulateToolCall` records call, returns mock response
- [ ] **Mock test (integration)**: `runTask` invokes Claude, full flow executes against mocks

---

### MCP Tools - CRM

#### US-008: CRM Tool - lead_create
**Description**: MCP tool to create a new lead in CRM.

**Dependencies**: US-005

**Acceptance Criteria**:
- [ ] `src/mcp/crm/lead_create.ts` exists with tool definition
- [ ] Mock handler in `src/mocks/handlers/mcp-crm.ts`
- [ ] Accepts: name, email, company, source, notes
- [ ] Returns: leadId, created timestamp
- [ ] **Mock test**: Claude processes "Create lead for John Doe at Acme Corp" task, calls lead_create with correct params

---

#### US-009: CRM Tool - lead_update
**Description**: MCP tool to update an existing lead.

**Dependencies**: US-008

**Acceptance Criteria**:
- [ ] `src/mcp/crm/lead_update.ts` exists with tool definition
- [ ] Mock handler registered
- [ ] Accepts: leadId, fields to update (status, notes, tags, etc.)
- [ ] Returns: success, updated fields
- [ ] **Mock test**: Claude processes "Mark lead L-123 as contacted" task, calls lead_update correctly

---

#### US-010: CRM Tool - lead_search
**Description**: MCP tool to search/filter leads.

**Dependencies**: US-008

**Acceptance Criteria**:
- [ ] `src/mcp/crm/lead_search.ts` exists with tool definition
- [ ] Mock handler returns configurable lead list
- [ ] Accepts: query, filters (status, tags, date range)
- [ ] Returns: array of matching leads
- [ ] **Mock test**: Claude processes "Find all leads tagged 'hot'" task, calls lead_search with tag filter

---

### MCP Tools - Email

#### US-011: Email Tool - send_email
**Description**: MCP tool to send a single email.

**Dependencies**: US-005, US-006

**Acceptance Criteria**:
- [ ] `src/mcp/email/send_email.ts` exists with tool definition
- [ ] Mock handler in `src/mocks/handlers/mcp-email.ts`
- [ ] Accepts: to, subject, body, from (optional)
- [ ] Returns: messageId, sent timestamp
- [ ] Triggers `pre-send` hook
- [ ] **Mock test**: Claude processes email task, pre-send hook allows, email sent with correct params

---

#### US-012: Mailchimp Tool - create_campaign
**Description**: MCP tool to create a Mailchimp email campaign.

**Dependencies**: US-011

**Acceptance Criteria**:
- [ ] `src/mcp/email/mailchimp_create_campaign.ts` exists
- [ ] Mock handler registered
- [ ] Accepts: name, subject, listId, content
- [ ] Returns: campaignId, status
- [ ] **Mock test**: Claude creates campaign from task instruction

---

#### US-013: Mailchimp Tool - get_stats
**Description**: MCP tool to get campaign statistics.

**Dependencies**: US-012

**Acceptance Criteria**:
- [ ] `src/mcp/email/mailchimp_get_stats.ts` exists
- [ ] Mock handler returns configurable stats
- [ ] Accepts: campaignId
- [ ] Returns: opens, clicks, bounces, unsubscribes
- [ ] **Mock test**: Claude checks campaign performance as part of feedback-activity task

---

### MCP Tools - Social Media

#### US-014: X/Twitter Tool - post
**Description**: MCP tool to post on X/Twitter.

**Dependencies**: US-005, US-006

**Acceptance Criteria**:
- [ ] `src/mcp/social/x_post.ts` exists
- [ ] Mock handler in `src/mocks/handlers/mcp-social.ts`
- [ ] Accepts: content, mediaUrls (optional)
- [ ] Returns: postId, url
- [ ] Triggers `pre-send` hook
- [ ] **Mock test**: Claude posts GM tweet, hook allows, post created

---

#### US-015: X/Twitter Tool - get_engagement
**Description**: MCP tool to get post engagement metrics.

**Dependencies**: US-014

**Acceptance Criteria**:
- [ ] `src/mcp/social/x_get_engagement.ts` exists
- [ ] Mock handler returns configurable metrics
- [ ] Accepts: postId or query for recent posts
- [ ] Returns: likes, retweets, replies, impressions
- [ ] **Mock test**: Claude gets top 5 performing posts for inspiration task

---

#### US-016: LinkedIn Tool - post
**Description**: MCP tool to post on LinkedIn.

**Dependencies**: US-005, US-006

**Acceptance Criteria**:
- [ ] `src/mcp/social/linkedin_post.ts` exists
- [ ] Mock handler registered
- [ ] Accepts: content, mediaUrls (optional), visibility
- [ ] Returns: postId, url
- [ ] Triggers `pre-send` hook
- [ ] **Mock test**: Claude posts LinkedIn update, hook allows

---

#### US-017: Instagram Tool - post
**Description**: MCP tool to post on Instagram.

**Dependencies**: US-005, US-006

**Acceptance Criteria**:
- [ ] `src/mcp/social/instagram_post.ts` exists
- [ ] Mock handler registered
- [ ] Accepts: mediaUrl, caption, hashtags
- [ ] Returns: postId, url
- [ ] Triggers `pre-send` hook
- [ ] **Mock test**: Claude posts Instagram content

---

#### US-018: Instagram Tool - get_insights
**Description**: MCP tool to get Instagram post/account insights.

**Dependencies**: US-017

**Acceptance Criteria**:
- [ ] `src/mcp/social/instagram_get_insights.ts` exists
- [ ] Mock handler returns configurable insights
- [ ] Accepts: postId or account-level query
- [ ] Returns: reach, impressions, engagement, saves
- [ ] **Mock test**: Claude gets 5 best performing GM posts for inspiration

---

#### US-019: Nostr Tool - publish_note
**Description**: MCP tool to publish a note on Nostr.

**Dependencies**: US-005, US-006

**Acceptance Criteria**:
- [ ] `src/mcp/social/nostr_publish_note.ts` exists
- [ ] Mock handler registered
- [ ] Accepts: content, tags
- [ ] Returns: eventId, relays published to
- [ ] Triggers `pre-send` hook
- [ ] **Mock test**: Claude publishes Nostr note

---

#### US-020: Bluesky Tool - post
**Description**: MCP tool to post on Bluesky.

**Dependencies**: US-005, US-006

**Acceptance Criteria**:
- [ ] `src/mcp/social/bluesky_post.ts` exists
- [ ] Mock handler registered
- [ ] Accepts: content, images (optional)
- [ ] Returns: uri, cid
- [ ] Triggers `pre-send` hook
- [ ] **Mock test**: Claude posts to Bluesky

---

#### US-021: Facebook Tool - post
**Description**: MCP tool to post on Facebook.

**Dependencies**: US-005, US-006

**Acceptance Criteria**:
- [ ] `src/mcp/social/facebook_post.ts` exists
- [ ] Mock handler registered
- [ ] Accepts: content, mediaUrls, pageId
- [ ] Returns: postId, url
- [ ] Triggers `pre-send` hook
- [ ] **Mock test**: Claude posts Facebook update

---

#### US-022: YouTube Tool - upload
**Description**: MCP tool to upload video to YouTube.

**Dependencies**: US-005, US-006

**Acceptance Criteria**:
- [ ] `src/mcp/social/youtube_upload.ts` exists
- [ ] Mock handler registered
- [ ] Accepts: videoPath, title, description, tags
- [ ] Returns: videoId, url
- [ ] Triggers `pre-send` hook
- [ ] **Mock test**: Claude uploads YouTube video

---

#### US-023: TikTok Tool - post
**Description**: MCP tool to post on TikTok.

**Dependencies**: US-005, US-006

**Acceptance Criteria**:
- [ ] `src/mcp/social/tiktok_post.ts` exists
- [ ] Mock handler registered
- [ ] Accepts: videoPath, caption, sounds
- [ ] Returns: videoId, url
- [ ] Triggers `pre-send` hook
- [ ] **Mock test**: Claude posts TikTok video

---

### MCP Tools - Paid Ads

#### US-024: Google Ads Tool - create_campaign
**Description**: MCP tool to create a Google Ads campaign.

**Dependencies**: US-005

**Acceptance Criteria**:
- [ ] `src/mcp/ads/google_ads_create_campaign.ts` exists
- [ ] Mock handler in `src/mocks/handlers/mcp-ads.ts`
- [ ] Accepts: name, budget, targeting, keywords
- [ ] Returns: campaignId, status
- [ ] **Mock test**: Claude creates Google Ads campaign from task

---

#### US-025: Google Ads Tool - get_performance
**Description**: MCP tool to get campaign performance metrics.

**Dependencies**: US-024

**Acceptance Criteria**:
- [ ] `src/mcp/ads/google_ads_get_performance.ts` exists
- [ ] Mock handler returns configurable metrics
- [ ] Accepts: campaignId, dateRange
- [ ] Returns: impressions, clicks, conversions, spend, ROAS
- [ ] **Mock test**: Claude analyzes ad performance for optimization task

---

#### US-026: Meta Ads Tool - create_ad
**Description**: MCP tool to create a Facebook/Meta ad.

**Dependencies**: US-005

**Acceptance Criteria**:
- [ ] `src/mcp/ads/meta_ads_create_ad.ts` exists
- [ ] Mock handler registered
- [ ] Accepts: adSetId, creative, targeting
- [ ] Returns: adId, status
- [ ] **Mock test**: Claude creates Meta ad from task

---

#### US-027: LinkedIn Ads Tool - create_campaign
**Description**: MCP tool to create a LinkedIn Ads campaign.

**Dependencies**: US-005

**Acceptance Criteria**:
- [ ] `src/mcp/ads/linkedin_ads_create_campaign.ts` exists
- [ ] Mock handler registered
- [ ] Accepts: name, budget, targeting, creatives
- [ ] Returns: campaignId, status
- [ ] **Mock test**: Claude creates LinkedIn ad campaign

---

### MCP Tools - Website/CMS

#### US-028: CMS Tool - create_page
**Description**: MCP tool to create a website page.

**Dependencies**: US-005

**Acceptance Criteria**:
- [ ] `src/mcp/cms/create_page.ts` exists
- [ ] Mock handler in `src/mocks/handlers/mcp-cms.ts`
- [ ] Accepts: title, slug, content, template
- [ ] Returns: pageId, url
- [ ] **Mock test**: Claude creates landing page from task

---

#### US-029: CMS Tool - update_content
**Description**: MCP tool to update page content.

**Dependencies**: US-028

**Acceptance Criteria**:
- [ ] `src/mcp/cms/update_content.ts` exists
- [ ] Mock handler registered
- [ ] Accepts: pageId, content, section
- [ ] Returns: success, updated timestamp
- [ ] **Mock test**: Claude updates blog post content

---

#### US-030: Blog Tool - create_post
**Description**: MCP tool to create a blog post.

**Dependencies**: US-028

**Acceptance Criteria**:
- [ ] `src/mcp/cms/create_blog_post.ts` exists
- [ ] Mock handler registered
- [ ] Accepts: title, content, categories, tags, publishDate
- [ ] Returns: postId, url
- [ ] **Mock test**: Claude creates and schedules blog post

---

### MCP Tools - Human Feedback

#### US-031: Matrix Tool - send_message
**Description**: MCP tool to send a message to Matrix channel for human feedback.

**Dependencies**: US-005

**Acceptance Criteria**:
- [ ] `src/mcp/matrix/send_message.ts` exists
- [ ] Mock handler in `src/mocks/handlers/mcp-matrix.ts`
- [ ] Accepts: roomId, message
- [ ] Returns: eventId
- [ ] **Mock test**: Claude sends task completion confirmation to Matrix

---

#### US-032: Matrix Tool - get_messages
**Description**: MCP tool to read messages from Matrix channel.

**Dependencies**: US-031

**Acceptance Criteria**:
- [ ] `src/mcp/matrix/get_messages.ts` exists
- [ ] Mock handler returns configurable message list
- [ ] Accepts: roomId, since (timestamp), limit
- [ ] Returns: array of messages with sender, content, timestamp
- [ ] **Mock test**: Claude reads feedback messages and creates follow-up task

---

### MCP Tools - Analytics

#### US-033: Google Analytics Tool - get_traffic
**Description**: MCP tool to get website traffic data.

**Dependencies**: US-005

**Acceptance Criteria**:
- [ ] `src/mcp/analytics/ga_get_traffic.ts` exists
- [ ] Mock handler in `src/mocks/handlers/mcp-analytics.ts`
- [ ] Accepts: dateRange, dimensions (source, medium, page)
- [ ] Returns: sessions, users, pageviews, bounceRate
- [ ] **Mock test**: Claude analyzes traffic as part of optimization task

---

#### US-034: WooCommerce Tool - get_sales
**Description**: MCP tool to get sales data from WooCommerce.

**Dependencies**: US-005

**Acceptance Criteria**:
- [ ] `src/mcp/analytics/woocommerce_get_sales.ts` exists
- [ ] Mock handler returns configurable sales data
- [ ] Accepts: dateRange, productId (optional)
- [ ] Returns: orders, revenue, averageOrderValue
- [ ] **Mock test**: Claude checks sales impact of recent campaign

---

### Claude Code Artifacts

#### US-035: Task-Add Command
**Description**: Claude Code command `/task-add` for adding tasks to the queue.

**Dependencies**: US-002

**Acceptance Criteria**:
- [ ] `src/.claude/commands/task-add.md` exists
- [ ] Command prompts for task description, priority
- [ ] Adds task to `src/tasks.json` with pending status
- [ ] **Mock test**: Claude invokes /task-add during execution, new task appears in queue

---

#### US-036: Task-Status Command
**Description**: Claude Code command `/task-status` for viewing task queue.

**Dependencies**: US-002

**Acceptance Criteria**:
- [ ] `src/.claude/commands/task-status.md` exists
- [ ] Displays all tasks grouped by status
- [ ] Shows pending count, in-progress, recently completed
- [ ] **Mock test**: Claude invokes /task-status, sees current queue state

---

#### US-037: Pre-Send Hook
**Description**: Claude Code hook that runs before outbound actions (email, social posts).

**Dependencies**: US-006

**Acceptance Criteria**:
- [ ] `src/.claude/hooks/pre-send.sh` exists
- [ ] Receives tool name and input as arguments
- [ ] Checks content against brand voice guidelines
- [ ] Checks for prohibited phrases
- [ ] Exit 0 to allow, exit 1 to block
- [ ] **Mock test**: Hook blocks email with prohibited phrase, allows compliant email

---

### Integration

#### US-038: End-to-End Task Execution
**Description**: Full integration test of task execution with all mocks.

**Dependencies**: US-003, US-004, US-007, US-011, US-014, US-018

**Acceptance Criteria**:
- [ ] Test harness set up with all mock tools
- [ ] Example complex task: "Check 5 best Instagram posts, create inspired GM post"
- [ ] Claude reads task, calls instagram_get_insights, creates content, calls instagram_post
- [ ] Task marked completed in tasks.json
- [ ] All tool calls recorded and assertable
- [ ] **Mock test**: Full feedback-activity-repeat pattern verified with mock assertions

---

#### US-039: Context Files Setup
**Description**: Create example context files for brand voice, ICP, templates, and playbook.

**Dependencies**: US-001

**Acceptance Criteria**:
- [ ] `src/context/brand/voice.md` exists with tone guidelines
- [ ] `src/context/product/overview.md` exists with product description
- [ ] `src/context/audience/icp.md` exists with ideal customer profile
- [ ] `src/context/templates/` has example email and social templates
- [ ] `src/context/playbook.md` exists as starter file for learned strategies (Claude updates this over time)
- [ ] Marketing prompt references these files

---

## Technical Notes

### Directory Structure
```
src/
├── .claude/
│   ├── commands/
│   │   ├── task-add.md
│   │   └── task-status.md
│   └── hooks/
│       ├── pre-send.sh
│       ├── pre-bash.sh
│       ├── pre-read.sh
│       └── pre-write.sh
├── mcp/
│   ├── crm/
│   ├── email/
│   ├── social/
│   ├── ads/
│   ├── cms/
│   ├── matrix/
│   └── analytics/
├── mocks/
│   ├── interceptor.ts
│   ├── hooks.ts
│   ├── harness.ts
│   ├── fixtures/
│   └── handlers/
├── context/
│   ├── brand/
│   ├── product/
│   ├── audience/
│   ├── templates/
│   └── playbook.md
├── tasks.json
├── wiggum.sh
└── marketing-prompt.md
```

### Mock Testing Pattern
Each tool's acceptance criteria includes a mock test that:
1. Sets up test harness with configured mocks
2. Provides a task that would trigger the tool
3. Runs Claude (simulated) with the task
4. Asserts correct tool calls were made with expected parameters
5. Verifies hooks triggered appropriately
