---
description: Create a standalone note for this Claude Code session
allowed-tools: ["Bash(/Users/bruno/.config/scripts/claude-session-note.sh:*)"]
---

Review our entire conversation and create a comprehensive standalone session note. Since this is a standalone note (not a daily log entry), provide thorough documentation including context, code snippets, and details that would be valuable for future reference.

Format the note as follows:

**Title:** short-descriptive-title (2-4 words, lowercase with hyphens, describing the main topic. Examples: "log-session-improvement", "nvim-plugin-setup", "git-workflow-fix")

**Tags:** #tag1, #tag2, #tag3 (relevant topic tags like #nvim, #git, #dotfiles, #debugging, #refactoring, etc.)

**Summary:**

Write a comprehensive note covering:

1. **Context & Goal**: What was the initial problem or goal? What prompted this work?

2. **Key Changes Made**: Document the main changes with specifics:
   - Files created/modified (with paths)
   - Key code snippets (use markdown code blocks with language tags)
   - Configuration changes
   - Technical decisions and rationale

3. **Problems & Solutions**: If any issues were encountered:
   - What went wrong
   - How it was debugged/resolved
   - Key insights or learnings

4. **Outcome & Impact**: What was accomplished? How does this improve the workflow/codebase?

5. **Related Notes/References**: Any relevant file paths, related concepts, or follow-up items

Use proper markdown formatting with headings (##, ###), code blocks with syntax highlighting, bullet points, and inline code formatting. Make this a valuable reference document, not just a summary.

Then use the Bash tool to execute this command to create the standalone note in your Obsidian vault:

```bash
echo 'YOUR_CONTENT_HERE' | /Users/bruno/.config/scripts/claude-session-note.sh
```

Replace YOUR_CONTENT_HERE with the complete formatted content (including title, tags, and the comprehensive summary). Make sure to properly escape any quotes or special characters.
