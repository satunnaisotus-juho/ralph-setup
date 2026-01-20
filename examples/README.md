# PRD Feedback Examples

This directory contains examples of PRDs and their analysis for iteratively improving the `/ralph-prd` planning tool.

## Purpose

Each example captures:
1. The original feature request and generated PRD
2. Analysis of problems encountered during implementation
3. Suggested improvements for future PRDs
4. Optionally, an improved version of the PRD

## Directory Structure

```
examples/
├── README.md                    # This file
├── _template/                   # Template for new examples
│   ├── input/
│   │   ├── request.md           # Original feature request
│   │   └── ralph-prd-snapshot.md # Copy of command used
│   ├── output/
│   │   ├── PRD.md               # Generated PRD
│   │   └── prd.json             # Converted for Ralph
│   ├── execution/
│   │   └── summary.md           # Execution summary (optional)
│   ├── analysis/
│   │   ├── problems.md          # Identified issues
│   │   ├── improvements.md      # Suggested improvements
│   │   └── PRD-improved.md      # Revised PRD (optional)
│   └── metadata.json            # Example metadata
│
└── <example-name>/              # Each example follows this structure
    └── ...
```

## Creating a New Example

1. Copy `_template/` to a new directory with a descriptive name
2. Fill in `input/request.md` with the original feature request
3. Copy the current `/ralph-prd` command to `input/ralph-prd-snapshot.md`
4. Add the generated `PRD.md` and `prd.json` to `output/`
5. Run `/ralph-analyze` to interactively generate the analysis
6. Update `metadata.json` with relevant information

## metadata.json Schema

```json
{
  "name": "example-name",
  "created": "2026-01-20",
  "command_version": "git commit hash or version",
  "source_project": "path or URL to implementation repo",
  "analysis_status": "pending | analyzed | improved",
  "tags": ["ui", "api", "database", "integration"]
}
```

### Analysis Status Values

- `pending` - Example added but not yet analyzed
- `analyzed` - Problems and improvements documented
- `improved` - Includes a revised PRD version

## Workflow

```
1. Run /ralph-prd on feature request
           ↓
2. Convert with /ralph-prd-to-json
           ↓
3. Execute Ralph until completion (all stories pass)
           ↓
4. Run /ralph-analyze (interactive) ← AFTER Ralph completes
           ↓
5. Review and validate analysis
           ↓
6. Update /ralph-prd based on learnings
```

**Important:** Run `/ralph-analyze` only after Ralph has finished (all stories pass) or you've decided to stop. The analysis requires a completed implementation to identify what worked and what didn't.

## Using Examples to Improve /ralph-prd

After analyzing several examples:

1. Look for patterns across `improvements.md` files
2. Identify recurring problems or themes
3. Update `.claude/commands/ralph-prd.md` with new guidance
4. Track changes by incrementing the command version
