/**
 * Memory Extension
 *
 * Persistent memory across sessions. Mirrors Claude Code's memory system.
 *
 * - Global memories: ~/.pi/memory/ (user preferences, feedback)
 * - Project memories: <cwd>/.pi/memory/ (project-specific context)
 *
 * Memories are markdown files with YAML frontmatter (name, description, type).
 * MEMORY.md is the index file. The LLM manages memories using read/write tools.
 * This extension just loads and injects the indexes at each turn.
 */

import type { ExtensionAPI } from "@mariozechner/pi-coding-agent";
import * as fs from "node:fs";
import * as path from "node:path";
import * as os from "node:os";

const GLOBAL_MEMORY_DIR = path.join(os.homedir(), ".pi", "memory");
const MEMORY_INDEX = "MEMORY.md";

function readMemoryIndex(dir: string): string | null {
	const indexPath = path.join(dir, MEMORY_INDEX);
	try {
		const content = fs.readFileSync(indexPath, "utf-8");
		return content.trim() || null;
	} catch {
		return null;
	}
}

export default function (pi: ExtensionAPI) {
	pi.on("before_agent_start", async (_event, ctx) => {
		const projectMemoryDir = path.join(ctx.cwd, ".pi", "memory");

		const globalIndex = readMemoryIndex(GLOBAL_MEMORY_DIR);
		const projectIndex = readMemoryIndex(projectMemoryDir);

		if (!globalIndex && !projectIndex) return undefined;

		const parts: string[] = [];

		if (globalIndex) {
			parts.push(`## Global Memories (~/.pi/memory/)\n\n${globalIndex}`);
		}

		if (projectIndex) {
			parts.push(`## Project Memories (.pi/memory/)\n\n${projectIndex}`);
		}

		const content = parts.join("\n\n---\n\n");

		return {
			message: {
				customType: "memory-context",
				content: [{ type: "text", text: content }],
				display: false,
			},
		};
	});
}
