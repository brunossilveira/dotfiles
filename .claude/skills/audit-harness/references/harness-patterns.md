# Harness Engineering Patterns Reference

Evidence-backed patterns from cross-company analysis of production AI agent systems.

## The Core Insight

The scaffold matters more than the model. Same model, different harness = 36-point score difference (Claude Opus 4.5 CORE-Bench: 42% → 78%). Teams shipping the best agents are simplifying, not adding complexity.

## 1. Context Layering

**Pattern**: Load context in stages, not all upfront.

**Evidence**:
- Claude Code uses 6 layers: policies → CLAUDE.md → settings → MEMORY.md → history → git state
- Cursor: router + context retrieval pipeline
- Liu et al. (TACL 2024): U-shaped performance — highest at beginning/end, worst in middle

**What to check**:
- CLAUDE.md hierarchy present (org → project → user)
- MEMORY.md used for persistent learnings
- Git state available in context
- No massive blocks of static text injected at session start

**Anti-pattern**: Dumping everything into a single CLAUDE.md.

## 2. Progressive Disclosure

**Pattern**: Incrementally load context on-demand, not all upfront.

**Evidence**:
- Claude Code skill system: metadata always loaded (~100 words), SKILL.md on trigger (<5k words), references as-needed (unlimited)
- Claude-Mem: 955 tokens at 100% efficiency vs 25,000 tokens at 0.8% efficiency (26x improvement)
- Cursor lazy MCP loading: 46.9% token reduction (A/B tested, statistically significant)

**What to check**:
- Skills use the three-level loading pattern (metadata → SKILL.md → references)
- Reference material separated from SKILL.md body
- No large reference docs inlined into SKILL.md
- Scripts executable without loading into context

**Anti-pattern**: Static context loading — 25,000 tokens of noise at 0.8% efficiency ratio.

## 3. Tool Hygiene

**Pattern**: Fewer tools, primitives over integrations.

**Evidence**:
- Vercel: removed 80% of tools → tokens 145,463→67,483 (-54%), steps 100→19, latency 724s→141s, agent went from failing→succeeding
- Claude Code: ~18 primitives in 4 categories (CLI, files, web, orchestration)
- Manus: 5 complete rewrites, each removed things (not added)
- Manus token ratio: ~100:1 input-to-output

**What to check**:
- MCP server count (warn if >5, fail if >10)
- Tools are primitives (bash, grep, read/write) not custom wrappers
- No duplicate capabilities across tools
- Tool definitions not bloating context

**Thresholds**:
- Healthy: 0-3 MCP servers with focused tool sets
- Warning: 4-5 MCP servers or overlapping capabilities
- Fail: 6+ MCP servers or redundant tools

**Anti-pattern**: Preloading all tools when most go unused. Adding integrations when primitives suffice.

## 4. Safety Guardrails

**Pattern**: Automated checks that catch errors before they compound.

**Evidence**:
- SWE-Agent linter-gated edits: 3% performance drop without this single guardrail
- Claude Code: errors returned as tool results (never hidden)
- All leaders: preserve errors, show them to model as learning signals

**What to check**:
- PreToolUse hooks for destructive operations (git push, rm, etc.)
- File operation protections
- No error suppression in custom scripts
- Hooks that validate before execution, not just log after

**Anti-pattern**: Cleaning/hiding errors. Skipping validation hooks for speed.

## 5. Planning & Recovery

**Pattern**: Use structured planning tools to maintain coherence across long tasks.

**Evidence**:
- Claude Code TodoWrite: no-op tool that forces plan articulation, keeps agent on course
- Manus todo.md: rewriting keeps plan in recent attention window
- Both approaches keep the plan in the model's active context

**What to check**:
- Skills reference task/todo patterns for multi-step workflows
- Error handling strategies documented in skills
- Recovery procedures for common failure modes
- Plans kept in filesystem for on-demand access

**Anti-pattern**: No planning structure for complex workflows. Management agents that add orchestration layers.

## 6. System Prompt Budget

**Pattern**: Keep always-loaded context well under the model's attention threshold.

**Evidence**:
- Dex Horthy "12 Factor Agents": at 40% of model capacity, enters "dumb zone" — signal-to-noise degrades, attention fragments
- Claude Code core system prompt: ~2,896 tokens
- Long context without filtering: 15-47% performance drop (research consensus)

**What to check**:
- Estimate total tokens of always-loaded content (CLAUDE.md files + settings descriptions)
- Flag if estimated >5,000 tokens of always-loaded content
- Check for redundant information across layers
- Ensure reference material is loaded on-demand, not always

**Thresholds**:
- Healthy: <3,000 tokens always-loaded
- Warning: 3,000-5,000 tokens
- Fail: >5,000 tokens of always-loaded custom content

**Anti-pattern**: Putting everything in CLAUDE.md. Inlining reference docs instead of using skills/references pattern.

## 7. Simplicity

**Pattern**: Complexity should be earned, not designed upfront. The best teams are removing, not adding.

**Evidence**:
- Manus: "5 rewrites, each removed things"
- All leaders converged on single flat loop (while tool_calls: execute → capture → append → call)
- LangChain DeepAgents: 52.8% → 66.5% from harness change alone
- Devin: 34% → 67% PR merge rate through simplification

**What to check**:
- Number of skills (warn if >10)
- Settings complexity (custom commands count, hook count)
- Skills that duplicate built-in capabilities
- Over-abstracted workflows that could be simpler

**Anti-pattern**: Over-engineering. Adding features "just in case." Complex orchestration when a flat loop works.

## Key Benchmarks Summary

| Metric | Value | Source |
|--------|-------|--------|
| Harness impact on same model | +36 points | CORE-Bench (Opus 4.5) |
| Lazy vs static loading | 26x efficiency | Claude-Mem |
| Lazy MCP token savings | 46.9% reduction | Cursor A/B test |
| Tool removal impact | -54% tokens, -81% steps | Vercel |
| Linter guardrail value | 3% performance | SWE-Agent |
| Context capacity limit | 40% before degradation | 12 Factor Agents |
| Long context penalty | 15-47% drop | Research consensus |

## Company Case Studies

- **Claude Code**: Reference implementation — 6-layer context, ~18 primitives, TodoWrite planning, skill system for progressive disclosure
- **Cursor**: Model-specific harness tuning, lazy MCP loading, semantic search with custom embeddings
- **Manus**: KV-cache optimization, all tools permanently loaded with logit masking, filesystem offloading
- **SWE-Agent**: Purpose-built agent-computer interfaces, linter-gated edits, observation compression
- **Vercel**: Dramatic improvement from removing tools (80% removal → agent went from failing to succeeding)
