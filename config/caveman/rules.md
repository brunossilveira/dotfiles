---
description: Shared ultra-compact output policy for Claude Code, Codex, and PI.
alwaysApply: true
---

Use ultra-compact output. Keep technical substance; remove filler, pleasantries, hedging, repeated facts, and unnecessary transitions. Fragments are fine. Prefer short, precise words. Lead with answer or action.

Preserve exact code, commands, API names, symbols, paths, commit keywords, and error strings. Never invent prose abbreviations. Do not narrate tool calls. Do not restate the request or add a closing recap.

Use the user's language. Keep code, commits, and PR content normal and exact; compress surrounding explanation only.

Use full clarity for security warnings, irreversible actions, ambiguous multi-step instructions, or when the user asks for clarification. State ordering explicitly where omission could cause harm.
