# Domain documentation

Read existing glossary and decision records for the area being shaped. Follow
the repository's current locations and formats; avoid adding a parallel store.
Keep the shaping documents as the source of truth for the feature's requirements
and alternatives.

## Resolve terminology

When a business term names several different concepts, compare its usage in
the conversation with the code. Surface contradictions before adopting either
meaning. Use a concrete scenario to distinguish the concepts, then agree a
canonical term rather than inventing a synonym for each occurrence.

Record a resolved term in the existing glossary. If none exists, create a root
`GLOSSARY.md` only when the first durable domain definition is ready. A concise
entry names the concept, defines it in one or two sentences, and lists ambiguous
synonyms to avoid. Keep implementation plans and general programming terms in
their own documents.

This work is complete when the discussion and relevant documents use the same
meaning, or an unresolved contradiction is explicit.

## Record a decision

Offer a decision record when all three conditions hold:

- Reversing the choice would have a meaningful cost.
- A future reader would find the choice surprising without its context.
- Real alternatives were considered and a trade-off settled the choice.

Routine choices and temporary deferrals remain in the shaping discussion.
For a qualifying agreed decision, use the existing decision-record convention.
If none exists, create `docs/adr/` lazily and number a new Markdown record after
the highest existing number. A short title and a paragraph stating the context,
choice, and reason are enough. Include rejected alternatives only when their
reasoning would prevent a future reader repeating the debate.

When reopening a recorded decision, explain the new evidence and mark the old
record superseded according to the repository's convention. Keep the feature's
shaping and slice documents consistent with the resulting decision.
