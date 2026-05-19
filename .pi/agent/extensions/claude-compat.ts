/**
 * Claude Code compatibility layer.
 *
 * - Loads .claude/rules/ (alwaysApply only) into the system prompt
 * - Registers .claude/commands/*.md as /claude:<name> slash commands
 */

import type { ExtensionAPI } from "@mariozechner/pi-coding-agent";
import * as fs from "node:fs";
import * as path from "node:path";

function parseFrontmatter(content: string): { meta: Record<string, string | boolean>; body: string } {
	const delim = content.startsWith("---\r\n") ? "---\r\n" : "---\n";
	if (!content.startsWith(delim)) return { meta: {}, body: content };

	const end = content.indexOf("\n---", delim.length);
	if (end === -1) return { meta: {}, body: content };

	const yaml = content.slice(delim.length, end);
	const body = content.slice(end + 4).replace(/^\r?\n/, "");
	const meta: Record<string, string | boolean> = {};

	for (const line of yaml.split("\n")) {
		const m = line.match(/^([\w][\w-]*):\s*(.+)$/);
		if (!m) continue;
		const val = m[2]!.trim();
		meta[m[1]!] = val === "true" ? true : val === "false" ? false : val;
	}

	return { meta, body };
}

function mdFiles(dir: string): string[] {
	try {
		return fs
			.readdirSync(dir)
			.filter((f) => f.endsWith(".md"))
			.sort();
	} catch {
		return [];
	}
}

export default function (pi: ExtensionAPI) {
	pi.on("before_agent_start", async (event, ctx) => {
		const rulesDir = path.join(ctx.cwd, ".claude", "rules");
		const files = mdFiles(rulesDir);
		if (files.length === 0) return undefined;

		const blocks: string[] = [];
		for (const file of files) {
			const content = fs.readFileSync(path.join(rulesDir, file), "utf-8");
			const { meta, body } = parseFrontmatter(content);
			if (meta.alwaysApply === true) {
				blocks.push(`### ${file}\n${body.trim()}`);
			}
		}

		if (blocks.length === 0) return undefined;

		return {
			systemPrompt: event.systemPrompt + `\n\n## Project Rules (.claude/rules)\n\n${blocks.join("\n\n")}`,
		};
	});

	pi.on("session_start", async (_event, ctx) => {
		const commandsDir = path.join(ctx.cwd, ".claude", "commands");
		for (const file of mdFiles(commandsDir)) {
			const name = file.replace(/\.md$/, "");
			const filePath = path.join(commandsDir, file);

			pi.registerCommand(`claude:${name}`, {
				description: parseFrontmatter(fs.readFileSync(filePath, "utf-8")).meta.description as string || `Claude command: ${name}`,
				handler: async (args, cmdCtx) => {
					const { body } = parseFrontmatter(fs.readFileSync(filePath, "utf-8"));
					const prompt = args ? `${body.trim()}\n\nArguments: ${args}` : body.trim();
					cmdCtx.ui.notify(`Running claude:${name}`, "info");
					pi.sendMessage({
						role: "user",
						content: [{ type: "text", text: prompt }],
						display: false,
					});
				},
			});
		}
	});
}
