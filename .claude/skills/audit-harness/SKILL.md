---
name: audit-harness
description: This skill should be used when users want to audit, review, or improve their Claude Code harness setup. It evaluates the .claude/ directory against evidence-backed patterns from production AI agent systems and produces a scored report with actionable recommendations.
---

# Audit Harness

Evaluate a Claude Code `.claude/` configuration against evidence-backed harness engineering patterns. Produce a scored report (0-100) with findings and actionable recommendations.

## When to Use

- User asks to audit, review, or improve their Claude Code setup
- User wants to optimize their `.claude/` directory configuration
- User asks about harness engineering best practices for their project

## Scoring Rubric

9 dimensions, 0-3 raw scale each, weighted to 100 total points.

| # | Dimension | Wt | 0 (Missing) | 1 (Partial) | 2 (Good) | 3 (Excellent) |
|---|-----------|-----|-------------|-------------|----------|--------------|
| 1 | Context Layering | 15 | No CLAUDE.md or single flat dump | CLAUDE.md exists but monolithic | CLAUDE.md + some layering (memory or user-level) | Full hierarchy (org/project/user), CLAUDE.md as map, MEMORY.md present |
| 2 | Progressive Disclosure | 15 | All context loaded upfront | Some skills but references inlined | Skills with separate SKILL.md, some references | Three-level loading (metadata/SKILL.md/references/), scripts without context |
| 3 | Tool Hygiene | 10 | 6+ MCP servers or heavy duplication | 4-5 MCP servers or some overlap | 1-3 MCP servers, mostly primitives | 0-3 focused MCP servers, no duplication, primitives over wrappers |
| 4 | Safety Guardrails | 10 | No hooks or protections | Some settings restrictions but no hooks | PreToolUse hooks for some destructive ops | Hooks for destructive ops, validation before execution, remediation messages |
| 5 | Planning & Recovery | 5 | No planning patterns | Some skills mention steps but unstructured | Skills reference task/todo patterns | Structured planning, error handling, recovery procedures, plans as artifacts |
| 6 | System Prompt Budget | 15 | >5,000 tokens always-loaded | 3,000-5,000 tokens, some redundancy | <3,000 tokens, minimal redundancy | <3,000 tokens, zero redundancy, every line drives behavior |
| 7 | Simplicity | 10 | >10 skills, heavy over-engineering | 6-10 skills or duplication of built-ins | 3-5 focused skills | Minimal config, no duplication, complexity earned not designed |
| 8 | Agent Legibility | 10 | Critical knowledge outside repo | Some conventions documented but gaps | Most decisions in-repo, self-documenting | All conventions in-repo, agents navigate without external knowledge |
| 9 | Mechanical Enforcement | 10 | Rules only in docs, nothing enforced | Some linter/CI enforcement | Hooks or linters for key rules | Full enforcement, agent-friendly error messages, drift detection |

**Formula:** `weighted_score = (raw / 3) * weight`

**Grades:** A (90+), B (75-89), C (60-74), D (40-59), F (<40)

## Audit Process

### Phase 1: Discover

Scan the target directory for `.claude/` configuration. Use Glob and Read to map what exists:

```
.claude/
  CLAUDE.md          # Project instructions
  settings.json      # Tool permissions, hooks, MCP servers
  skills/            # Skill definitions
  commands/          # Custom slash commands
  memory/            # Persistent memory files
```

Also check for:
- Root-level `CLAUDE.md` (project instructions)
- `~/.claude/CLAUDE.md` (user-level instructions)
- Organization-level CLAUDE.md if applicable
- `CLAUDE.md` files in subdirectories
- `docs/` or similar structured knowledge directories
- Linter configs, CI files, or scripts that enforce conventions

**Verify References:** Extract every file path and markdown link from all CLAUDE.md files. Use Glob to check each path resolves. Record total links, valid count, broken count, and broken paths.

**Stats:** Record line counts for CLAUDE.md, total .md files under docs/ and .claude/, directory count.

### Phase 2: Assess

Evaluate each dimension using the rubric. Read `references/harness-patterns.md` for detailed evidence and thresholds.

For each dimension determine:
- **Raw score** (0-3)
- **Evidence** (what was observed)
- **Gaps** (what's missing)
- **Recommendations** (specific actions)

#### Minimal Setup Handling

For bare configurations (just a CLAUDE.md), use these defaults to avoid penalizing simplicity:

| Dimension | Default | Rationale |
|-----------|---------|-----------|
| Progressive Disclosure | 2 | Nothing to disclose yet |
| Tool Hygiene | 3 | No custom tools = clean |
| Planning & Recovery | 2 | No complex workflows yet |
| Simplicity | 3 | Minimal is simple |

Assess remaining dimensions on their merits. Focus recommendations on highest-impact next steps for the user's maturity level.

### Phase 3: Report

Output a markdown report using this template:

```markdown
## Claude Code Harness Audit

**Target**: `<path>` | **Date**: <date>
**Root CLAUDE.md**: N lines | **Docs**: N .md files across N directories

### Score: N/100 -- Grade X

| # | Dimension | Wt | Raw | Score | |
|---|-----------|-----|-----|-------|-|
| 1 | Context Layering | 15 | N/3 | N.N | [========] |
| 2 | Progressive Disclosure | 15 | N/3 | N.N | [========] |
| 3 | Tool Hygiene | 10 | N/3 | N.N | [========] |
| 4 | Safety Guardrails | 10 | N/3 | N.N | [========] |
| 5 | Planning & Recovery | 5 | N/3 | N.N | [========] |
| 6 | System Prompt Budget | 15 | N/3 | N.N | [========] |
| 7 | Simplicity | 10 | N/3 | N.N | [========] |
| 8 | Agent Legibility | 10 | N/3 | N.N | [========] |
| 9 | Mechanical Enforcement | 10 | N/3 | N.N | [========] |

Bar: 8 chars wide. `=` filled, `-` empty. Proportional to raw/3.

### Detailed Findings

#### D1 -- Context Layering (N/3 -> N.N/15)
**Evidence:** ...
**Gaps:** ...
**Recommendations:** ...

(repeat for all 9 dimensions)

### Top 3 Quick Wins

Rank by largest gap between current weighted score and maximum.

1. **[Dimension]** -- [specific action]. Impact: +N.N points.
2. **[Dimension]** -- [specific action]. Impact: +N.N points.
3. **[Dimension]** -- [specific action]. Impact: +N.N points.

### Correctness Check

| Metric | Count |
|--------|-------|
| Total links | N |
| Valid links | N |
| Broken links | N |
| Broken paths | [list or "none"] |

### Benchmarks

| Metric | Value | Source |
|--------|-------|--------|
| Harness impact on same model | +36 points | CORE-Bench |
| Lazy vs static loading | 26x efficiency | Claude-Mem |
| Tool removal impact | -54% tokens, -81% steps | Vercel |
| Linter guardrail value | 3% performance | SWE-Agent |
| Context capacity limit | 40% before degradation | 12 Factor Agents |
```
