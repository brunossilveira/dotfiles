/**
 * Worktree extension.
 *
 * `/worktree [name]` creates (or reuses) an isolated git worktree under
 * `.worktrees/<name>` on its own branch and switches the session into it, so
 * edits never collide with other work in the same checkout. With no name, one
 * is generated. On exit, a clean worktree is removed automatically.
 */

import { appendFile, readFile } from "node:fs/promises";
import { existsSync } from "node:fs";
import { basename, dirname, join, resolve } from "node:path";
import type { ExtensionAPI } from "@earendil-works/pi-coding-agent";
import {
	createOrReuseWorktree,
	currentBranch,
	deleteBranchIfMerged,
	getMainWorktreeRoot,
	getRepoRoot,
	removeWorktreeIfClean,
	validateBranchName,
} from "./git.js";
import { applyWorktreeInclude } from "./include.js";
import { generateWorktreeName } from "./naming.js";
import { getWorktreeDir } from "./paths.js";
import { switchToWorktreeSession } from "./session.js";

function messageOf(error: unknown, fallback: string): string {
	return error instanceof Error && error.message ? error.message : fallback;
}

/** Add `.worktrees` to `.gitignore` if a `.gitignore` exists and lacks it. */
async function ensureWorktreesIgnored(repoRoot: string): Promise<void> {
	const file = join(repoRoot, ".gitignore");
	if (!existsSync(file)) return;
	const content = await readFile(file, "utf8");
	if (content.split(/\r?\n/).some((l) => l.trim() === ".worktrees" || l.trim() === ".worktrees/")) return;
	await appendFile(file, `${content.length === 0 || content.endsWith("\n") ? "" : "\n"}.worktrees\n`, "utf8");
}

export default function worktreeExtension(pi: ExtensionAPI): void {
	pi.registerCommand("worktree", {
		description: "Create or reuse a git worktree and switch the session into it",
		handler: async (args, ctx) => {
			await ctx.waitForIdle();

			const repoRoot = await getRepoRoot(pi.exec, ctx.cwd);
			if (!repoRoot) {
				ctx.ui.notify("Not inside a git repository.", "error");
				return;
			}

			const branch = args.trim() || generateWorktreeName();
			if (!(await validateBranchName(pi.exec, repoRoot, branch))) {
				ctx.ui.notify(`Invalid branch name: ${branch}`, "error");
				return;
			}

			const worktreeDir = getWorktreeDir(repoRoot, branch);

			try {
				await ensureWorktreesIgnored(repoRoot);
			} catch (error) {
				ctx.ui.notify(messageOf(error, "Failed to update .gitignore"), "warning");
			}

			const created = await createOrReuseWorktree(pi.exec, repoRoot, branch, worktreeDir);
			if (!created.ok) {
				ctx.ui.notify(created.error, "error");
				return;
			}

			if (created.base) {
				if (!created.base.ref) {
					ctx.ui.notify("Based on local HEAD (no remote default branch)", "info");
				} else if (created.base.fetched) {
					ctx.ui.notify(`Based on ${created.base.ref} (freshly fetched)`, "info");
				} else {
					ctx.ui.notify(`Based on ${created.base.ref} (fetch failed — may be stale)`, "warning");
				}
			}

			try {
				const copied = await applyWorktreeInclude(pi.exec, repoRoot, worktreeDir);
				if (copied.length > 0) ctx.ui.notify(`Copied ${copied.length} ignored file(s) into worktree`, "info");
			} catch (error) {
				ctx.ui.notify(`.worktreeinclude: ${messageOf(error, "copy failed")}`, "warning");
			}

			try {
				await switchToWorktreeSession(ctx, branch, worktreeDir);
			} catch (error) {
				ctx.ui.notify(messageOf(error, "Failed to switch to worktree session"), "error");
			}
		},
	});

	// Auto-remove the worktree on exit when it is clean (git refuses otherwise).
	pi.on("session_shutdown", async (_event, ctx) => {
		const cwd = ctx.cwd;
		if (basename(dirname(cwd)) !== ".worktrees") return;

		const mainRoot = await getMainWorktreeRoot(pi.exec, cwd);
		if (!mainRoot || resolve(mainRoot) === resolve(cwd)) return;

		const branch = await currentBranch(pi.exec, cwd);
		if (!(await removeWorktreeIfClean(pi.exec, mainRoot, cwd))) return;
		if (branch) await deleteBranchIfMerged(pi.exec, mainRoot, branch);
	});
}
