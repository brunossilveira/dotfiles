/**
 * Read Before Edit Extension
 *
 * Enforces that files must be read before they can be edited or overwritten.
 * - edit: always blocked if the file hasn't been read
 * - write: blocked if the file already exists and hasn't been read (new files are OK)
 *
 * This is tool-level enforcement, not just a prompt instruction.
 */

import type { ExtensionAPI } from "@mariozechner/pi-coding-agent";
import { resolve } from "node:path";
import { access } from "node:fs/promises";

export default function (pi: ExtensionAPI) {
	const readFiles = new Set<string>();

	function resolvePath(filePath: string): string {
		return resolve(process.cwd(), filePath);
	}

	pi.on("tool_call", async (event, _ctx) => {
		// Track reads
		if (event.toolName === "read") {
			const filePath = event.input.path as string;
			readFiles.add(resolvePath(filePath));
			return undefined;
		}

		// Block edit on unread files
		if (event.toolName === "edit") {
			const filePath = event.input.path as string;
			if (!readFiles.has(resolvePath(filePath))) {
				return {
					block: true,
					reason: `You must read "${filePath}" before editing it. Use the read tool first.`,
				};
			}
			return undefined;
		}

		// Block write on existing unread files (new files are allowed)
		if (event.toolName === "write") {
			const filePath = event.input.path as string;
			const resolved = resolvePath(filePath);

			try {
				await access(resolved);
				// File exists — must have been read first
				if (!readFiles.has(resolved)) {
					return {
						block: true,
						reason: `You must read "${filePath}" before overwriting it. Use the read tool first. Only use write for new files or after reading the existing file.`,
					};
				}
			} catch {
				// File doesn't exist — creating new file is fine
			}

			return undefined;
		}

		return undefined;
	});

	// Clear tracking when session changes
	pi.on("session_start", async () => {
		readFiles.clear();
	});
}
