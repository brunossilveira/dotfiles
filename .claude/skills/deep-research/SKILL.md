---
name: deep-research
description: Research focused technical questions or broader topics using cited primary sources. Use for documentation or API investigations, comparisons, and comprehensive reports; choose depth to match the question.
license: MIT
---

# Research

State the question and choose the smallest research mode that can answer it.
Use the request and repository context to infer scope. Ask only when missing
information would materially change the investigation.

## Choose the depth

- **Focused:** one concrete question, such as an API behavior or compatibility
  constraint. Investigate directly, return a concise answer with citations, and
  stop when the answer is supported or a precise evidence gap remains.
- **Standard:** several related questions or a comparison. Identify the decision
  criteria, investigate each, and synthesize one answer. Delegate independent
  reading only when it helps; do not require a research plan or separate writer.
- **Comprehensive:** an explicitly requested deep report, or a question with
  several independent areas that need sustained investigation. Read
  [comprehensive-research.md](references/comprehensive-research.md) for research
  roles, coordination, notes, and report delivery.

For depth examples or an analytical framework, consult the relevant section of
[research-frameworks.md](references/research-frameworks.md). Its full report
checklist is for comprehensive reports. Source and page counts are examples,
not quotas or substitutes for answering the question.

## Evidence for every mode

For technical claims, prefer the source that owns the behavior: official docs,
the applicable specification, the installed version's code, or a first-party
API. Trace secondary explanations to that source. Check dates and versions
when they affect the answer; distinguish measured results from inferences.

Follow important contradictions instead of counting agreeing sources. Explain
what the evidence establishes, what remains uncertain, and any environment or
access limitation. Verify repository claims against its actual code and
configuration rather than a remembered convention.

## Deliver and stop

Answer the question with citations beside the claims they support. For focused
or standard work, save a report only when the user requests an artifact or an
existing workflow requires one; use the repository's established location and
format. Comprehensive work follows the linked report procedure.

The investigation is complete when each material question has a supported
answer or an explicit gap, and any requested artifact exists and has been read
back. Report a gap without turning it into permission for new access, external
writes, or implementation work.
