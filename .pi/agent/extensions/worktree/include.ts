import { copyFile, mkdir, readFile } from "node:fs/promises";
import { dirname, join } from "node:path";
import type { Exec } from "./types.js";

/** Parse a `.worktreeinclude` file: non-empty, non-comment lines. */
export function parseWorktreeInclude(content: string): string[] {
	return content
		.split(/\r?\n/)
		.map((l) => l.trim())
		.filter((l) => l.length > 0 && !l.startsWith("#"));
}

/**
 * Copy gitignored files matching `.worktreeinclude` (e.g. `.env`, secrets) from
 * the main checkout into the new worktree. Git does the pattern matching via
 * `--exclude-from`; `--others` guarantees only untracked files are considered,
 * so tracked files are never duplicated. Returns the relative paths copied.
 */
export async function applyWorktreeInclude(exec: Exec, repoRoot: string, worktreeDir: string): Promise<string[]> {
	const includeFile = join(repoRoot, ".worktreeinclude");

	let raw: string;
	try {
		raw = await readFile(includeFile, "utf8");
	} catch {
		return [];
	}
	if (parseWorktreeInclude(raw).length === 0) return [];

	const r = await exec("git", ["ls-files", "--others", "--ignored", "-z", `--exclude-from=${includeFile}`], { cwd: repoRoot });
	if (r.code !== 0) return [];

	const files = r.stdout.split("\0").filter(Boolean);
	const copied: string[] = [];
	for (const rel of files) {
		const to = join(worktreeDir, rel);
		await mkdir(dirname(to), { recursive: true });
		await copyFile(join(repoRoot, rel), to);
		copied.push(rel);
	}
	return copied;
}
