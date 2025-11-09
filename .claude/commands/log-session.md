---
description: Summarize the conversation and log it to daily work notes
allowed-tools: ["Bash(/Users/bruno/.config/scripts/claude-session-log.sh:*)"]
---

Review our entire conversation and create a concise summary (3-5 sentences) covering:
- The main questions asked
- Key problems solved
- Important outcomes and decisions
- Format it using Markdown and YAML Formatter

Then use the Bash tool to execute this command to log it to my daily Obsidian work notes:

```bash
echo 'YOUR_SUMMARY_HERE' | /Users/bruno/.config/scripts/claude-session-log.sh
```

Replace YOUR_SUMMARY_HERE with the actual summary text you generated. Make sure to properly escape any quotes or special characters in the summary.
