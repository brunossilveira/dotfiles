import { resolve } from "node:path";

/**
 * Turn a branch name into a filesystem-safe directory name.
 * Strips anything outside [A-Za-z0-9._-] (so `feature/auth` -> `feature-auth`)
 * and neutralizes names that would resolve to `.`/`..` or a hidden/empty dir.
 */
export function sanitizeWorktreeName(name: string): string {
	const replaced = name.trim().replace(/[^a-zA-Z0-9._-]/g, "-");

	if (replaced === "" || /^\.+$/.test(replaced)) {
		return "wt";
	}

	return replaced;
}

export function getWorktreesDir(repoRoot: string): string {
	return resolve(repoRoot, ".worktrees");
}

export function getWorktreeDir(repoRoot: string, safeName: string): string {
	return resolve(getWorktreesDir(repoRoot), safeName);
}
