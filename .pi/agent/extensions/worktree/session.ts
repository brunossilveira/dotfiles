import { existsSync } from "node:fs";
import { SessionManager, type ExtensionCommandContext } from "@earendil-works/pi-coding-agent";

export const WORKTREE_CONTEXT_TYPE = "worktree-context";

export function buildContextMessage(branch: string, worktreeDir: string): string {
	return `You are now in git worktree \`${worktreeDir}\` on branch \`${branch}\`. Keep all changes within this worktree.`;
}

/**
 * Fork the current session into `worktreeDir` (or start a fresh one if the
 * current session was never persisted), record a context note, and switch pi
 * into it. The conversation continues; only the working directory changes.
 */
export async function switchToWorktreeSession(ctx: ExtensionCommandContext, branch: string, worktreeDir: string): Promise<void> {
	const seed = ctx.sessionManager.getSessionFile();
	const manager =
		seed !== undefined && existsSync(seed)
			? SessionManager.forkFrom(seed, worktreeDir)
			: SessionManager.create(worktreeDir);

	manager.resetLeaf();
	manager.appendCustomMessageEntry(WORKTREE_CONTEXT_TYPE, buildContextMessage(branch, worktreeDir), false, { branch, worktreeDir });

	const file = manager.getSessionFile();
	if (!file || !existsSync(file)) {
		throw new Error(`Worktree session was not persisted${file ? `: ${file}` : ""}`);
	}

	const result = await ctx.switchSession(file, {
		withSession: async (next) => {
			next.ui.notify(`Switched to worktree: ${worktreeDir}`, "info");
		},
	});
	if (result.cancelled) throw new Error("Switch to worktree session was cancelled.");
}
