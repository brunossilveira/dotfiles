# Porting notes

## Provenance

`roles/`, `role-templates/`, `worker-common.prompt`, `clean-architecture.md`,
and `squad.conf.example` are copied verbatim from
[unclebob/swarm-forge](https://github.com/unclebob/swarm-forge), branch `squad`,
commit `9b7f405` (2026-08-17). The upstream repository carries no LICENSE file.

Verbatim on purpose: this is the corpus to adapt from, not the finished set.
Two changes have been applied since the copy — the Gherkin lane is gone and the
contracts are no longer EDN (below). Everything else still assumes swarm-forge's
runtime.

## Applied so far

**Dropped the Gherkin / QA-procedure lane.** `gherkin-writer`, `gherkin-reviewer`,
`qa-procedure-writer`, and `qa-procedure-reviewer` are deleted, and the leader's
template roster no longer lists them. Stories go straight to the implementer.
Nine transient templates remain: `analyst`, `implementer`, `cleaner`,
`code-reviewer`, `hardener`, `qa`, `architect`, `senior-implementer`, `merger`.

**Converted contracts from EDN to `key: value`,** so the bash advisor can read
them with `grep`/`read` and no Clojure. One pair per line, keys snake_case,
lists space-separated, booleans literal `true` / `false`:

```
role: implementer
handoff_targets: squad-leader
may_spawn: false
writes: production-code unit-tests acceptance-tests
artifact_roots: src/ test/
```

Prompt references were repointed at the new paths (`role-templates/<x>.contract`,
`reference/clean-architecture.md`). The conversion is otherwise faithful — dead
values came across unchanged and are listed below.

**Kept on disk but out of the pipeline.** `DESIGN.md` drops `qa` (CI on the pull
request is the independent verification) and `troubleshooter` (the operator is in
the session). Their prompts and contracts are still here; delete them once the
advisor exists and nothing references them.

## What the copied prompts assume that we do not have

**Helper commands.** Prompts call `squad_next.sh`, `squad_assign.sh`,
`squad_packet.sh`, `squad_approval.sh`, `squad_theme.sh`, `squad_spawn_request.sh`,
`squad_event.sh`, `squad_run.sh`, `squad_tool.sh`, `squad_retire.sh`,
`squad_recover.sh`, `squad_review.sh`, `squad_status.sh`, `squad_report.sh`,
`squad_dashboard_request.sh`, `squadd.sh`. None exist here. Upstream these are
~17k lines of Babashka; the plan is a much smaller bash advisor plus a handful
of state helpers, so most of these commands need to collapse or disappear.

**Tooling.** Prompts name `bb`, `deps.edn`, `bb.edn`, `bb acceptance`,
`bb coverage`, CRAP/DRY/mutation tools, and `swarmforge/tool-table.edn`. All
Clojure-specific. Ruby/Rails and Go equivalents, or drop the requirement.

**Acceptance Pipeline Specification.** The implementer prompt owns a
generated-acceptance-test pipeline (`acceptance/generated/`, `acceptance/steps/`,
a Gherkin parser, an NDJSON mutator worker). That is a large product commitment
riding along inside a role prompt.

**Gherkin leftovers in the surviving files.** Dropping the lane removed the four
roles, not every mention of them. Still to strip when the prompts get rewritten:
`gherkin-parser` and `gherkin-mutator` in `hardener.contract`'s
`required_tool_ids`; the `features/` entries in the hardener and implementer
`artifact_roots`; `gherkin` and `qa-procedures` in the leader and troubleshooter
`forbidden_writes` (harmless, just stale); and the narrative paragraphs in
`analyst.prompt`, `implementer.prompt`, `qa.prompt`, `hardener.prompt`, and
`squad-leader.prompt` that route work through accepted Gherkin. `qa.prompt` in
particular is written around executing Gherkin and QA procedures, so its job
needs restating as plain independent verification.

**Runtime the prompts describe.** Handoff files delivered by a daemon, tmux
wake-up messages, `.swarmforge/handoffs/{outbox,inbox,sent,failed}`, dashboard
requests routed through the troubleshooter, a `squadd` daemon that owns main-git
merges. Our substrate is hacktopus sessions, Claude subagents, and headless
Codex — the transport paragraphs do not port, only the ideas behind them.

**Theme module map.** The leader authors one before theme approval, following an
upstream template we did not copy (`swarmforge/templates/theme-module-map.md`).
Copy it or drop the requirement.

## Ideas worth keeping regardless of how much prose survives

- Durable state as files, so a dead session loses nothing.
- One deterministic advisor as the only source of workflow order.
- Contracts with an explicit `forbidden-writes` list.
- Writer/reviewer pairs on different backends — the reviewer never edits.
- One writer for the main branch, so merges cannot race.
- Approvals as durable records: an approval nobody wrote down did not happen.
- A simulator that exercises the pipeline with no agents running.
