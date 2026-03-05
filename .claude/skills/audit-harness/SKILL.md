---
name: audit-harness
description: This skill should be used when users want to audit, review, or improve their Claude Code harness setup. It evaluates the .claude/ directory against evidence-backed patterns from production AI agent systems and produces a scorecard with actionable recommendations.
---

# Audit Harness

Evaluate a Claude Code `.claude/` configuration against evidence-backed harness engineering patterns. Produce a scorecard with findings and actionable recommendations.

## When to Use

- User asks to audit, review, or improve their Claude Code setup
- User wants to optimize their `.claude/` directory configuration
- User asks about harness engineering best practices for their project

## Audit Process

### Phase 1: Discover

Scan the target directory for `.claude/` configuration. Use Glob and Read to map what exists:

```
.claude/
├── CLAUDE.md          # Project instructions
├── settings.json      # Tool permissions, hooks, MCP servers
├── skills/            # Skill definitions
├── commands/          # Custom slash commands
├── memory/            # Persistent memory files
└── ...
```

Also check for:
- Root-level `CLAUDE.md` (project instructions)
- `~/.claude/CLAUDE.md` (user-level instructions)
- Organization-level CLAUDE.md if applicable
- `CLAUDE.md` files in subdirectories

### Phase 2: Assess

Evaluate against 7 categories. Read `references/harness-patterns.md` for detailed evidence and thresholds for each category.

#### Category 1: Context Layering
- Check for CLAUDE.md hierarchy (org → project → user levels)
- Check for MEMORY.md or memory/ directory
- Check if git state is available
- Flag if all context crammed into a single file

#### Category 2: Progressive Disclosure
- Check skills use three-level loading (metadata → SKILL.md → references/)
- Check that reference material is separated from SKILL.md body
- Flag large inlined content in SKILL.md files (>200 lines without references/)
- Check for scripts/ that can execute without context loading

#### Category 3: Tool Hygiene
- Count MCP servers in settings.json
- Check for overlapping tool capabilities
- Assess whether custom tools duplicate built-in primitives
- Thresholds: healthy (0-3 MCP), warning (4-5), fail (6+)

#### Category 4: Safety Guardrails
- Check for PreToolUse hooks in settings.json
- Look for destructive operation protections (git push, rm, file overwrites)
- Check if hooks validate before execution
- Flag absence of any safety hooks

#### Category 5: Planning & Recovery
- Check if skills reference task/todo patterns for multi-step work
- Look for error handling strategies in skills
- Check for recovery procedures in complex workflows

#### Category 6: System Prompt Budget
- Estimate token count of always-loaded content (CLAUDE.md files)
- Use rough heuristic: ~1 token per 4 characters, or ~1.3 tokens per word
- Thresholds: healthy (<3,000 tokens), warning (3,000-5,000), fail (>5,000)
- Flag redundant information across CLAUDE.md layers

#### Category 7: Simplicity
- Count total skills (warn if >10)
- Count custom commands
- Count hooks
- Flag skills that duplicate built-in capabilities
- Flag over-abstracted configurations

### Phase 3: Report

Output a markdown scorecard in this format:

```markdown
## Claude Code Harness Audit

**Target**: `<path>`
**Date**: <date>

### Scorecard

| # | Category | Status | Finding |
|---|----------|--------|---------|
| 1 | Context Layering | PASS/WARN/FAIL | <one-line summary> |
| 2 | Progressive Disclosure | PASS/WARN/FAIL | <one-line summary> |
| 3 | Tool Hygiene | PASS/WARN/FAIL | <one-line summary> |
| 4 | Safety Guardrails | PASS/WARN/FAIL | <one-line summary> |
| 5 | Planning & Recovery | PASS/WARN/FAIL | <one-line summary> |
| 6 | System Prompt Budget | PASS/WARN/FAIL | <one-line summary> |
| 7 | Simplicity | PASS/WARN/FAIL | <one-line summary> |

**Overall**: <X>/7 passing

### Recommendations

<Numbered list of specific, actionable recommendations ordered by impact>
```

### Scoring Rules

- **PASS**: Category meets or exceeds the pattern with no issues
- **WARN**: Partial implementation or approaching a threshold
- **FAIL**: Missing entirely or exceeding a threshold

### Minimal Setup Handling

For bare configurations (just a CLAUDE.md):
- Context Layering: WARN (single layer present, but no hierarchy)
- Progressive Disclosure: PASS (nothing to disclose yet)
- Tool Hygiene: PASS (no custom tools)
- Safety Guardrails: WARN or FAIL (no hooks)
- Planning & Recovery: PASS (no complex workflows yet)
- System Prompt Budget: Assess based on CLAUDE.md size
- Simplicity: PASS (minimal is simple)

Focus recommendations on highest-impact next steps for the user's maturity level.
