import { existsSync } from "node:fs";
import { SessionManager, type ExtensionCommandContext } from "@earendil-works/pi-coding-agent";

export const WORKTREE_CONTEXT_TYPE = "worktree-context";

type SessionMessage = Parameters<SessionManager["appendMessage"]>[0];

export function buildContextMessage(branch: string, worktreeDir: string): string {
	return `You are now in git worktree \`${worktreeDir}\` on branch \`${branch}\`. Keep all changes within this worktree.`;
}

/**
 * A synthetic, empty assistant message. pi defers writing a new session file
 * until it contains an assistant message, so appending this forces a brand-new
 * (never-persisted) session to flush to disk before we switch into it.
 */
function buildPersistenceSentinel(): SessionMessage {
	return {
		role: "assistant",
		content: [],
		api: "synthetic",
		provider: "pi-worktree",
		model: "session-persistence-sentinel",
		usage: { input: 0, output: 0, cacheRead: 0, cacheWrite: 0, totalTokens: 0, cost: { input: 0, output: 0, cacheRead: 0, cacheWrite: 0, total: 0 } },
		stopReason: "aborted",
		timestamp: Date.now(),
	} as SessionMessage;
}

/**
 * Fork the current session into `worktreeDir` (or start a fresh one if the
 * current session was never persisted), record a context note, and switch pi
 * into it. The conversation continues; only the working directory changes.
 */
export async function switchToWorktreeSession(ctx: ExtensionCommandContext, branch: string, worktreeDir: string): Promise<void> {
	const seed = ctx.sessionManager.getSessionFile();
	const hasPersistedSeed = seed !== undefined && existsSync(seed);
	const manager = hasPersistedSeed ? SessionManager.forkFrom(seed, worktreeDir) : SessionManager.create(worktreeDir);

	// forkFrom writes the file eagerly; a freshly created session does not until
	// it holds an assistant message, so seed one to guarantee it lands on disk.
	if (!hasPersistedSeed) {
		manager.appendMessage(buildPersistenceSentinel());
	}

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
