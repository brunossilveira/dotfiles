---
name: gesso
description: Present a plan, comparison, report, diagram, or review as an interactive HTML artifact the user annotates in the browser, with feedback returned via gesso poll. Use when a response is easier to grasp visually than as prose, or when the user asks for an artifact, mockup, or review surface.
argument-hint: <what the artifact should show>
---

# Gesso

Gesso turns a complex response into an HTML artifact the user reviews in the
browser: they click elements or select text to annotate, write notes, and the
feedback comes back to you as structured JSON. Local-only by design — the
server binds 127.0.0.1, there is no publish/share command, and no telemetry.

The `gesso` binary is on PATH (source: `~/code/gesso`; update with
`make install` there).

## Request

$ARGUMENTS

If the request above is non-empty, build an artifact for it now. If empty,
infer what to visualize from the conversation.

## Workflow

1. Write the artifact to `.gesso/<name>.html` in the working directory
   (create the dir; it is globally gitignored).
2. `gesso open .gesso/<name>.html` — starts the loopback server if needed and
   opens the review session in the user's browser.
3. `gesso poll .gesso/<name>.html` — run as a background task. It blocks until
   the user sends feedback, then prints a JSON batch and exits. Feedback is
   durable on disk: if the poll or server dies, just re-run poll; nothing is
   lost.
4. Apply the feedback (edit the artifact or the underlying work it describes),
   then `gesso poll <file> --reply "<what you did>"` to answer in the chat and
   keep listening. The user must reload to see artifact changes (no live
   reload yet).
5. When poll returns `"session_ended": true`, the user is done — stop polling.
   You can also end it yourself with `gesso end <file>` once the review
   concludes.

## Feedback format

Poll output: `{"messages": [{role, text, annotations: [{kind, selector,
text}]}], "session_ended": bool}`. `kind` is `element` (user clicked) or
`text` (user selected); `selector` locates the spot in the artifact; `text` is
the annotated content. Treat annotations as pointers into the artifact — find
the corresponding content and apply the note to it.

## Artifact guidance

- Reach for an artifact when structure beats prose: plans, option
  comparisons, architecture summaries, review reports, before/after diffs,
  tabular data. Don't use it for short answers or quick confirmations.
- Make the most important decisions, risks, and next actions obvious at a
  glance: sections, cards, and tables over long paragraphs; visual hierarchy
  over emphasis-by-adjective.
- Self-contained HTML with inline CSS. Reference sibling files with relative
  paths only if you also create them next to the artifact. No CDN dependencies
  unless the user asks — artifacts should render offline.
- Prevent horizontal overflow: wrap or truncate long unbreakable strings
  (paths, hashes, URLs); give nested flex/grid children `min-width: 0`.
- Match the subject's design system when the artifact previews a specific
  app's UI; otherwise keep it plain and readable (system fonts, generous
  spacing, restrained color).

## Environment

`GESSO_PORT` (default 4377), `GESSO_STATE_DIR` (default
`~/.local/state/gesso`), `GESSO_NO_OPEN=1` to suppress the browser launch.
State (sessions, message logs) lives in the state dir; `gesso stop` shuts the
server down (it also self-stops when the last session ends).
