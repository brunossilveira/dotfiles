# Dotfiles

My dotfiles. Use at your own risk :)

## Installation

Run the full installation:

```bash
./install.sh
```

## Development & Debugging

For debugging the installation process, you can use bash debug flags:

```bash
# Run with verbose output to see all commands being executed
bash -x install.sh

# Run with additional debugging
bash -xv install.sh
```

The installation is idempotent - you can re-run it safely without issues.

## Agent workflows

Pick the entry point that matches the outcome you need. Workflow entries
produce a deliverable; reusable guidance supports those workflows. These roles
describe how the pieces fit without changing their invocation policies.

| Situation | Start with | Role |
|-----------|------------|------|
| Explore requirements and compare solutions | [shaping](.claude/skills/shaping/SKILL.md) | Workflow |
| Break an agreed plan into verifiable tickets | [to-tickets](.agents/skills/to-tickets/SKILL.md) | Workflow |
| Implement a task or ticket end to end | [work](.agents/skills/work/SKILL.md) | Workflow |
| Investigate a focused question or research a wider topic | [deep-research](.claude/skills/deep-research/SKILL.md) | Workflow |
| Find refactoring candidates | [cqc-review](.claude/skills/cqc-review/SKILL.md) | Workflow |
| Restructure code while preserving behavior | [safe-refactoring](.claude/skills/safe-refactoring/SKILL.md) | Guidance |
| Refine the current change | [simplify](.pi/agent/skills/simplify/SKILL.md) | Guidance |
| Check what a change could break elsewhere | [blast-radius](.agents/skills/blast-radius/SKILL.md) | Workflow |
| Audit a contributor PR before merge | [pr-audit](.pi/agent/skills/pr-audit/SKILL.md) | Workflow |
| Address reviews and failing PR checks | [fix-pr](.agents/skills/fix-pr/SKILL.md) | Workflow |
| Push the branch and open a PR | [open-pr](.agents/skills/open-pr/SKILL.md) | Workflow |
| Prevent a recurring agent mistake | [correct](.agents/skills/correct/SKILL.md) | Workflow |
| Continue work in another agent or directory | [handoff](.agents/skills/handoff/SKILL.md) | Workflow |
| Author shared skills or agent instructions | [skill-authoring](.claude/skills/skill-authoring/SKILL.md) | Guidance |

Typical flow: `shaping` → `to-tickets` when needed → `work` for each ticket.
Use `handoff` when the work needs to travel; session logs remain the archive.
Reusable guidance stays available to workflows that invoke it. A workflow's
external writes still require authorization for that action.

Shared skills retain one source of truth through directory symlinks. New slash
commands live in `.agents/skills/<name>/SKILL.md`, with a symlink under
`.claude/commands/` and an entry in `link.sh`. Preview installation changes with
`./link.sh --dry-run`.

The reproduction, design, review, authoring, shaping, research, handoff, and
ticket improvements draw on [Matt Pocock's skills](https://github.com/mattpocock/skills/tree/4ae2317ddb22b046e26455e4f9c9b3aaaf62212d),
adapted to the existing workflows here.
