# Breadboarding

Use a breadboard to trace behavior across the places, actions, and state that
make a shape work. Match the fidelity to the open question: describe the current
system when investigating it, or the selected shape when planning a change.

## Map the behavior

1. Name the places involved, such as a page, dialog, CLI command, API endpoint,
   or background-job context. Follow the user action or other triggering event.
2. List the UI affordances where there is a UI. Give each a stable ID and name.
3. List the non-UI affordances: handlers, queries, state stores, and external
   operations that the behavior depends on.
4. Record outgoing connections by ID: what invokes what, which state is read
   or written, and which result becomes visible to the caller.

Use tables such as these, omitting the UI table for a non-UI system:

| ID | Place | UI affordance | Wires out |
|----|-------|---------------|-----------|
| U1 | Search page | Submit query | N1 |
| U2 | Search page | Results list | — |

| ID | Place | Non-UI affordance | Wires out |
|----|-------|-------------------|-----------|
| N1 | Search endpoint | Search matching records | N2 |
| N2 | Search endpoint | Return matching records | U2 |

Add state or data-flow columns when those are needed to explain the mechanism.
Keep unresolved mechanisms visibly flagged instead of inventing connections.
Trace an error or empty result when it changes the design.

A Mermaid diagram may render the same IDs, grouped by place.

The breadboard is ready for slicing when the triggering event can be followed
through its relevant actions and state to an observable result, every wire
resolves to a named affordance, and remaining design questions are explicit.
Resolve any question that would change a proposed slice before calling it ready.

## Slicing

Start with the smallest useful route through the breadboard that produces an
observable outcome. Include the state and behavior that route needs across its
responsible layers; save other routes for later increments.

For each slice, name its outcome, the affordance IDs it covers, what proves it
works, and any earlier slice it genuinely requires. Backend behavior can be
verified through an API, CLI, job result, or invariant; a UI is not mandatory.
Show the affordances for each slice in the slices document, preserving their
IDs so changes can be traced back to the selected shape.

Check that the slices collectively cover the selected shape without inventing
extra scope. A slice is ready when its prerequisites and acceptance are clear
and it can be demonstrated or verified on its own. Use `to-tickets` when these
agreed increments need implementation tickets; keep the slicing procedure here.
