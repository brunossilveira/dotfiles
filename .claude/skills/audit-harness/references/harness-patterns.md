# Harness Engineering Patterns Reference

Evidence-backed patterns from cross-company analysis of production AI agent systems.

## The Core Insight

The scaffold matters more than the model. Same model, different harness = 36-point score difference (Claude Opus 4.5 CORE-Bench: 42% → 78%). Teams shipping the best agents are simplifying, not adding complexity.

## 1. Context Layering

**Pattern**: Load context in stages, not all upfront. Treat the main instruction file as a map, not a manual.

**Evidence**:
- Claude Code uses 6 layers: policies → CLAUDE.md → settings → MEMORY.md → history → git state
- Cursor: router + context retrieval pipeline
- Liu et al. (TACL 2024): U-shaped performance — highest at beginning/end, worst in middle
- OpenAI Codex team: AGENTS.md kept to ~100 lines as a "table of contents" pointing to deeper docs. The "one big file" approach failed — crowded out task context, caused pattern-matching instead of intentional navigation, rotted instantly

**What to check**:
- CLAUDE.md hierarchy present (org → project → user)
- CLAUDE.md acts as a map with pointers, not an encyclopedia
- MEMORY.md used for persistent learnings
- Git state available in context
- No massive blocks of static text injected at session start

**Anti-patterns**:
- Dumping everything into a single CLAUDE.md
- Monolithic instruction file that "rots instantly" — agents can't tell what's still true
- Knowledge living in Slack/Docs/heads instead of versioned in-repo artifacts

## 2. Progressive Disclosure

**Pattern**: Incrementally load context on-demand, not all upfront. Agents start with a small, stable entry point and are taught where to look next.

**Evidence**:
- Claude Code skill system: metadata always loaded (~100 words), SKILL.md on trigger (<5k words), references as-needed (unlimited)
- Claude-Mem: 955 tokens at 100% efficiency vs 25,000 tokens at 0.8% efficiency (26x improvement)
- Cursor lazy MCP loading: 46.9% token reduction (A/B tested, statistically significant)
- OpenAI Codex: structured docs/ directory with indexed design docs, execution plans, and references — agents navigate to what they need rather than loading everything

**What to check**:
- Skills use the three-level loading pattern (metadata → SKILL.md → references)
- Reference material separated from SKILL.md body
- No large reference docs inlined into SKILL.md
- Scripts executable without loading into context
- Knowledge organized so agents can navigate to relevant sections

**Anti-pattern**: Static context loading — 25,000 tokens of noise at 0.8% efficiency ratio. "When everything is important, nothing is."

## 3. Tool Hygiene

**Pattern**: Fewer tools, primitives over integrations. Favor "boring" technologies that are composable, have stable APIs, and are well-represented in training data.

**Evidence**:
- Vercel: removed 80% of tools → tokens 145,463→67,483 (-54%), steps 100→19, latency 724s→141s, agent went from failing→succeeding
- Claude Code: ~18 primitives in 4 categories (CLI, files, web, orchestration)
- Manus: 5 complete rewrites, each removed things (not added)
- Manus token ratio: ~100:1 input-to-output
- OpenAI Codex: sometimes cheaper to reimplement subsets of functionality than to wrap opaque upstream libraries. Favor dependencies that can be "fully internalized and reasoned about in-repo"

**What to check**:
- MCP server count (warn if >5, fail if >10)
- Tools are primitives (bash, grep, read/write) not custom wrappers
- No duplicate capabilities across tools
- Tool definitions not bloating context
- Dependencies are agent-legible (composable, stable, well-documented)

**Thresholds**:
- Healthy: 0-3 MCP servers with focused tool sets
- Warning: 4-5 MCP servers or overlapping capabilities
- Fail: 6+ MCP servers or redundant tools

**Anti-pattern**: Preloading all tools when most go unused. Adding integrations when primitives suffice. Opaque dependencies that agents can't reason about.

## 4. Safety Guardrails

**Pattern**: Automated checks that catch errors before they compound. Promote rules from documentation into mechanically enforced code.

**Evidence**:
- SWE-Agent linter-gated edits: 3% performance drop without this single guardrail
- Claude Code: errors returned as tool results (never hidden)
- All leaders: preserve errors, show them to model as learning signals
- OpenAI Codex: custom linters with error messages that inject remediation instructions into agent context. "When documentation falls short, promote the rule into code." Structural tests enforce architectural invariants mechanically.

**What to check**:
- PreToolUse hooks for destructive operations (git push, rm, etc.)
- File operation protections
- No error suppression in custom scripts
- Hooks that validate before execution, not just log after
- Rules that are documented but not enforced (candidates for promotion to hooks/linters)

**Anti-patterns**:
- Cleaning/hiding errors — skipping validation hooks for speed
- Rules that exist only in documentation without mechanical enforcement
- Relying on agents to remember constraints instead of enforcing them

## 5. Planning & Recovery

**Pattern**: Use structured planning tools to maintain coherence across long tasks. Treat plans as first-class, versioned artifacts.

**Evidence**:
- Claude Code TodoWrite: no-op tool that forces plan articulation, keeps agent on course
- Manus todo.md: rewriting keeps plan in recent attention window
- Both approaches keep the plan in the model's active context
- OpenAI Codex: execution plans tracked in `docs/exec-plans/` with progress and decision logs checked into the repo. Active plans, completed plans, and tech debt all versioned and co-located so agents can operate without external context.

**What to check**:
- Skills reference task/todo patterns for multi-step workflows
- Error handling strategies documented in skills
- Recovery procedures for common failure modes
- Plans kept in filesystem for on-demand access
- When something fails, the response is "what capability is missing?" not "try harder"

**Anti-pattern**: No planning structure for complex workflows. Management agents that add orchestration layers. Retrying failures without diagnosing root cause.

## 6. System Prompt Budget

**Pattern**: Keep always-loaded context well under the model's attention threshold. Act as a map with pointers, not an encyclopedia.

**Evidence**:
- Dex Horthy "12 Factor Agents": at 40% of model capacity, enters "dumb zone" — signal-to-noise degrades, attention fragments
- Claude Code core system prompt: ~2,896 tokens
- Long context without filtering: 15-47% performance drop (research consensus)
- OpenAI Codex: "Context is a scarce resource. A giant instruction file crowds out the task, the code, and the relevant docs." AGENTS.md kept to ~100 lines.

**What to check**:
- Estimate total tokens of always-loaded content (CLAUDE.md files + settings descriptions)
- Flag if estimated >5,000 tokens of always-loaded content
- Check for redundant information across layers
- Ensure reference material is loaded on-demand, not always
- CLAUDE.md should be a map with pointers, not inline everything

**Thresholds**:
- Healthy: <3,000 tokens always-loaded
- Warning: 3,000-5,000 tokens
- Fail: >5,000 tokens of always-loaded custom content

**Anti-pattern**: Putting everything in CLAUDE.md. Inlining reference docs instead of using skills/references pattern. "Too much guidance becomes non-guidance."

## 7. Simplicity

**Pattern**: Complexity should be earned, not designed upfront. The best teams are removing, not adding.

**Evidence**:
- Manus: "5 rewrites, each removed things"
- All leaders converged on single flat loop (while tool_calls: execute → capture → append → call)
- LangChain DeepAgents: 52.8% → 66.5% from harness change alone
- Devin: 34% → 67% PR merge rate through simplification
- OpenAI Codex: team initially spent 20% of time cleaning up "AI slop." Solved by encoding "golden principles" and running recurring background cleanup agents — garbage collection, not manual cleanup.

**What to check**:
- Number of skills (warn if >10)
- Settings complexity (custom commands count, hook count)
- Skills that duplicate built-in capabilities
- Over-abstracted workflows that could be simpler
- Patterns that have drifted or rotted without maintenance

**Anti-pattern**: Over-engineering. Adding features "just in case." Complex orchestration when a flat loop works. Manual cleanup instead of automated entropy management.

## 8. Agent Legibility

**Pattern**: Optimize the codebase and configuration for agent readability. What agents can't access in-context effectively doesn't exist.

**Evidence**:
- OpenAI Codex: "From the agent's point of view, anything it can't access in-context while running effectively doesn't exist." Knowledge in Slack/Docs/heads is invisible to agents.
- OpenAI Codex: optimized code for agent legibility first — "boring" technologies preferred for composability, API stability, and training-data representation
- OpenAI Codex: made application UI, logs, and metrics directly legible to agents via Chrome DevTools Protocol, LogQL, PromQL
- Cursor: semantic search with custom embeddings trained on agent session traces

**What to check**:
- Important decisions/conventions documented in-repo (not in external tools)
- Configuration files are well-structured and self-documenting
- Skills include enough context for agent to navigate without external knowledge
- No critical knowledge that only lives in human memory or external docs

**Anti-pattern**: Tribal knowledge that isn't encoded. Opaque configurations without explanatory comments. Critical context living outside the repository.

## 9. Mechanical Enforcement

**Pattern**: Enforce invariants mechanically, not through instructions. Encode human taste into tooling so it applies everywhere at once.

**Evidence**:
- OpenAI Codex: custom linters enforce structured logging, naming conventions, file size limits, dependency direction rules. Lint error messages written to inject remediation into agent context.
- OpenAI Codex: "enforce boundaries centrally, allow autonomy locally" — rigid architectural model with strictly validated dependency directions
- SWE-Agent: linter-gated edits — 3% performance drop without
- OpenAI Codex: recurring "doc-gardening" agent scans for stale docs and opens fix-up PRs. Quality grades tracked per domain.

**What to check**:
- Rules in CLAUDE.md that could be promoted to hooks or linters
- Custom lint rules with agent-friendly error messages
- CI checks that validate configuration consistency
- Automated processes for detecting drift or staleness

**Anti-pattern**: Relying solely on written instructions. Rules that exist in docs but aren't enforced. Stale documentation without freshness checks.

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
| Agent-first throughput | 3.5 PRs/engineer/day | OpenAI Codex team |
| Agent-first codebase scale | ~1M lines, ~1500 PRs in 5 months | OpenAI Codex team |

## Company Case Studies

- **Claude Code**: Reference implementation — 6-layer context, ~18 primitives, TodoWrite planning, skill system for progressive disclosure
- **Cursor**: Model-specific harness tuning, lazy MCP loading, semantic search with custom embeddings
- **Manus**: KV-cache optimization, all tools permanently loaded with logit masking, filesystem offloading
- **SWE-Agent**: Purpose-built agent-computer interfaces, linter-gated edits, observation compression
- **Vercel**: Dramatic improvement from removing tools (80% removal → agent went from failing to succeeding)
- **OpenAI Codex**: Agent-first from day one — ~100-line AGENTS.md as map, structured docs/ as system of record, mechanical enforcement via custom linters, execution plans as versioned artifacts, recurring garbage-collection agents, progressive autonomy through depth-first capability building
