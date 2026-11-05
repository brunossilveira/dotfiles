# Comprehensive Research

Use this procedure after selecting comprehensive mode in the research
entrypoint. Scale the number of research threads to the independent questions,
not a fixed quota. When delegation is available and authorized, use fresh
contexts with narrow assignments and artifact pointers. Respect the harness's
concurrency limits; research sequentially when delegation is unavailable.

## Agent Architecture

### Lead Agent (You - the Orchestrator)

**Role**: Interview user, plan research threads, spawn and coordinate subagents

**Tools**: The available research, delegation, question, and file tools

**Responsibilities**:
- Resolve material scope questions not already answered by the request
- Perform initial reconnaissance
- Decompose the topic into independent research threads
- Spawn researcher agents in parallel
- Spawn report-writer agent after research completes

### Researcher Agents

**Role**: Execute focused research on assigned subtopic

**Tools**: Available search, source-reading, and file tools

**Responsibilities**:
- Search the web for information on assigned topic
- Fetch and analyze relevant pages
- Save structured research notes to `research_notes/` directory

**Output format**: Each researcher saves a markdown file to `research_notes/[subtopic-slug].md` with:
- Summary of findings
- Key facts and data points
- Source URLs with brief descriptions
- Notable quotes or excerpts
- Conflicts or gaps identified

### Report-Writer Agent

**Role**: Synthesize all research notes into final report

**Tools**: Available file-reading and writing tools

**Responsibilities**:
- Read all files from `research_notes/` directory
- Identify themes, patterns, and conflicts across sources
- Structure and write the final report
- Create the sources bibliography

## Research Process

### Phase 1: Interview and Scope Definition

Use the request and context to establish the following. Ask only about missing
information that changes the research:

1. **Research objectives**: What are they trying to understand or decide?
2. **Depth and breadth**: How comprehensive should the research be?
3. **Target audience**: Who will read this report?
4. **Key questions**: What specific questions need answering?
5. **Time constraints**: Is this time-sensitive information?
6. **Scope boundaries**: What should be explicitly included or excluded?

This phase is complete when the questions, scope, and requested output are clear.

### Phase 2: Initial Reconnaissance

After establishing scope, perform initial reconnaissance to identify the research landscape:

1. Conduct broad searches sufficient to map the topic space
2. Identify key subtopics, domains, and areas of focus
3. Note promising sources, authoritative voices, and research gaps
4. Create a research plan outlining the independent research threads

Save the research plan to `research_plan.md` documenting:
- The research threads identified
- Which researcher will handle each thread
- Expected output from each researcher

### Phase 3: Parallel Research (Researcher Agents)

Delegate independent threads within the available concurrency limit. Give each
researcher a focused assignment and a fresh context. Without delegation, work
through the same assignments directly.

**Spawning researcher agents:**

```
Delegate with the available agent tool:
- role: "researcher"
- prompt: Include these elements:
  1. Clear statement: "You are a RESEARCHER agent"
  2. Specific subtopic assignment
  3. Tool scope: "Search primary sources, read them, and write research notes"
  4. Output instructions: "Save your findings to research_notes/[subtopic].md"
  5. Format requirements for the research notes file
```

**Example researcher prompt:**
```
You are a RESEARCHER agent investigating: "Technical implementation of quantum error correction"

YOUR TOOL SCOPE: Search primary sources, read them, and write research notes.

TASK:
1. Find authoritative sources on quantum error correction implementation
2. Read promising sources to extract detailed information
3. Save your findings to research_notes/quantum-error-correction.md

OUTPUT FORMAT (save to research_notes/quantum-error-correction.md):
# Quantum Error Correction Implementation

## Summary
[2-3 paragraph summary of key findings]

## Key Findings
- [Bullet points of important facts, data, techniques]

## Sources
1. [URL] - [Brief description of what this source contributed]
2. [URL] - [Brief description]
...

## Notable Quotes
> "[Relevant quote]" - Source

## Gaps and Conflicts
- [Any conflicting information or areas needing more research]
```

Run only independent assignments concurrently; queue the rest within the
harness's limits. Use the available delegation tool and equivalent capabilities
for the example prompts above.

### Phase 4: Report Generation (Report-Writer Agent)

After all research threads complete, synthesize the notes. Use a separate
report-writer agent when available and useful:

```
Delegate with the available agent tool:
- role: "report-writer"
- prompt: Include these elements:
  1. Clear statement: "You are a REPORT-WRITER agent"
  2. Tool scope: "Find and read research notes, then write the report"
  3. Instructions to read all files from research_notes/
  4. Report structure requirements
  5. Output file paths for report and sources
```

**Report structure:**
- Executive Summary (2-3 paragraphs)
- Adaptive middle sections based on topic
- Critical Analysis
- Conclusions
- References (numbered citations)

**Sources file structure:**
- Numbered entries with URL, access date, type, key points, and relevance

**Writing guidelines:**
- Use numbered citations [1], [2], etc.
- Cross-reference findings across multiple researcher notes
- Note any conflicts or gaps in the research
- Use clear, precise academic language
- Include tables for comparisons where appropriate

### Phase 5: Output and Summary

After the report-writer completes:

1. Inform the user of the generated files:
   - `[topic]-report.md`: Main research report
   - `[topic]-sources.md`: Complete bibliography
   - `research_notes/`: Directory of raw research (can be deleted)

2. Provide a brief verbal summary of key findings

3. Offer to answer follow-up questions or expand on any section

## File Structure

```
./
├── research_plan.md           # Your research plan (Phase 2)
├── research_notes/            # Researcher agent outputs (Phase 3)
│   ├── subtopic-1.md
│   ├── subtopic-2.md
│   └── ...
├── [topic]-report.md          # Final report (Phase 4)
└── [topic]-sources.md         # Bibliography (Phase 4)
```

## Best Practices

### Agent Separation

- **Lead agent**: Coordinates delegated threads; researches directly when delegation is unavailable
- **Researchers**: ONLY search, fetch, and write notes - no synthesis
- **Report-writer**: ONLY reads notes and writes report - no new research

This separation ensures clean handoffs and reproducible results.

### Efficiency

- Parallelize independent research within the available concurrency limit
- Use the harness's configured models rather than assuming model names
- Clear task delineation prevents redundant research

## Common Patterns

### Comparative Research
When comparing technologies, approaches, or solutions:
- Assign one researcher per option being compared
- Assign one researcher for cross-cutting concerns (performance, cost, etc.)
- Report-writer creates comparison tables

### Technical Deep-Dives
When researching technical topics:
- Assign researchers to: fundamentals, implementation, case studies, limitations
- Report-writer structures from basics to advanced

### Market/Landscape Research
When surveying a domain or market:
- Assign researchers to: major players, emerging players, trends, analysis firms
- Report-writer categorizes and evaluates the landscape

### Historical/Evolution Research
When investigating how something developed:
- Assign researchers to different time periods or key events
- Report-writer creates timeline and connects to present
