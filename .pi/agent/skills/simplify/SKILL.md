---
name: simplify
description: Simplify and refine recently modified code for clarity, coherent responsibilities, consistency, and maintainability while preserving all functionality. Use after writing or modifying code.
---

Analyze recently modified code once for clarity, maintainability, and responsibility
placement. Apply only behavior-preserving refinements.

## Rules

1. **Preserve functionality**: Never change what the code does — only how it does it.

2. **Follow project conventions**: Read CLAUDE.md, AGENTS.md, and surrounding code to learn the project's style. Match it. Don't introduce patterns the codebase doesn't use.

3. **Enhance clarity**:
   - Reduce unnecessary complexity and nesting
   - Eliminate redundant code and abstractions
   - Improve names for variables and functions
   - Consolidate related logic
   - Remove comments that describe obvious code
   - Prefer explicit readable code over compact clever code

4. **Keep responsibilities coherent**: For each class or module the change
   added or grew, check whether it gained a concern with its own state or reason
   to change. Strong extraction signals include separate state clusters, both
   sides of a shared contract living far apart, and protocol logic mixed with
   transport. Extract only when the concern is genuinely independent; new files
   receive the same scrutiny as existing ones.

5. **Don't over-simplify**:
   - Don't create overly clever solutions that are hard to understand
   - Don't combine too many concerns into a single function
   - Don't remove helpful abstractions that improve organization
   - Don't prioritize fewer lines over readability
   - Don't make the code harder to debug or extend

6. **Scope**: Only refine recently modified code unless explicitly told otherwise.

## Process

1. Run `git diff` once to identify recently modified code
2. In the same pass, analyze clarity, consistency, and responsibility placement
3. Apply the project's own coding standards (from context files and surrounding code)
4. Verify all functionality is unchanged, unless the caller explicitly defers
   verification to a later final gate
5. Summarize only changes made and unresolved concerns; do not list clean
   verdicts for every file
