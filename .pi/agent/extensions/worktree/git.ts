import { existsSync } from "node:fs";
import { resolve } from "node:path";
import type { Exec } from "./types.js";

/** Where a new worktree branch is rooted. `ref` is null when no remote default exists (uses local HEAD). */
export interface WorktreeBase {
	ref: string | null;
	fetched: boolean;
}

type CreateResult = { ok: true; reused: boolean; base?: WorktreeBase } | { ok: false; error: string };

function errorOf(r: { stderr: string; stdout: string }, fallback: string): string {
	return r.stderr.trim() || r.stdout.trim() || fallback;
}

/** Repository root for `cwd`, or null when not inside a git repo. */
export async function getRepoRoot(exec: Exec, cwd: string): Promise<string | null> {
	const r = await exec("git", ["rev-parse", "--show-toplevel"], { cwd });
	if (r.code !== 0) return null;
	const root = r.stdout.trim();
	return root || null;
}

export async function validateBranchName(exec: Exec, repoRoot: string, branch: string): Promise<boolean> {
	const r = await exec("git", ["check-ref-format", "--branch", branch], { cwd: repoRoot });
	return r.code === 0;
}

async function branchExists(exec: Exec, repoRoot: string, branch: string): Promise<boolean> {
	const r = await exec("git", ["show-ref", "--verify", "--quiet", `refs/heads/${branch}`], { cwd: repoRoot });
	return r.code === 0;
}

/** Path of the worktree currently registered at `dir`, or null if `dir` isn't one. */
async function registeredWorktree(exec: Exec, repoRoot: string, dir: string): Promise<boolean> {
	const r = await exec("git", ["worktree", "list", "--porcelain"], { cwd: repoRoot });
	if (r.code !== 0) return false;
	const target = resolve(dir);
	return r.stdout
		.split("\n")
		.filter((l) => l.startsWith("worktree "))
		.some((l) => resolve(l.slice("worktree ".length).trim()) === target);
}

/** The origin default branch (e.g. `origin/main`), or null when there is no usable remote. */
async function originDefaultBranch(exec: Exec, repoRoot: string): Promise<string | null> {
	const sym = await exec("git", ["symbolic-ref", "--short", "refs/remotes/origin/HEAD"], { cwd: repoRoot });
	if (sym.code === 0 && sym.stdout.trim()) return sym.stdout.trim();

	for (const candidate of ["origin/main", "origin/master"]) {
		const r = await exec("git", ["show-ref", "--verify", "--quiet", `refs/remotes/${candidate}`], { cwd: repoRoot });
		if (r.code === 0) return candidate;
	}
	return null;
}

/**
 * Resolve the base for a new worktree branch: the origin default branch, fetched
 * fresh so it matches the remote. Falls back to local HEAD when no remote default
 * exists. `fetched` is false when the ref is present but couldn't be refreshed.
 */
export async function resolveWorktreeBase(exec: Exec, repoRoot: string): Promise<WorktreeBase> {
	const def = await originDefaultBranch(exec, repoRoot);
	if (!def) return { ref: null, fetched: false };

	const fetched = (await exec("git", ["fetch", "origin", def.replace(/^origin\//, "")], { cwd: repoRoot })).code === 0;
	return { ref: def, fetched };
}

/**
 * Create a worktree for `branch` at `dir`. New branches are rooted on a
 * freshly-pulled origin default branch; an existing branch is checked out as-is.
 * If `dir` already exists, reuse it only when it is a registered worktree.
 */
export async function createOrReuseWorktree(exec: Exec, repoRoot: string, branch: string, dir: string): Promise<CreateResult> {
	if (existsSync(dir)) {
		if (await registeredWorktree(exec, repoRoot, dir)) return { ok: true, reused: true };
		return { ok: false, error: `Path exists but is not a git worktree: ${dir}` };
	}

	if (await branchExists(exec, repoRoot, branch)) {
		const r = await exec("git", ["worktree", "add", dir, branch], { cwd: repoRoot });
		if (r.code !== 0) return { ok: false, error: errorOf(r, "Failed to create worktree") };
		return { ok: true, reused: false };
	}

	const base = await resolveWorktreeBase(exec, repoRoot);
	const args = base.ref
		? ["worktree", "add", "-b", branch, dir, base.ref]
		: ["worktree", "add", "-b", branch, dir];

	const r = await exec("git", args, { cwd: repoRoot });
	if (r.code !== 0) return { ok: false, error: errorOf(r, "Failed to create worktree") };
	return { ok: true, reused: false, base };
}

/** The main worktree root, resolved from inside any linked worktree. */
export async function getMainWorktreeRoot(exec: Exec, cwd: string): Promise<string | null> {
	const r = await exec("git", ["worktree", "list", "--porcelain"], { cwd });
	if (r.code !== 0) return null;
	const first = r.stdout.split("\n").find((l) => l.startsWith("worktree "));
	return first ? first.slice("worktree ".length).trim() : null;
}

export async function currentBranch(exec: Exec, cwd: string): Promise<string | null> {
	const r = await exec("git", ["rev-parse", "--abbrev-ref", "HEAD"], { cwd });
	const name = r.stdout.trim();
	return r.code === 0 && name && name !== "HEAD" ? name : null;
}

/**
 * Remove the worktree at `dir` (run from `mainRoot`). Uses a non-forced remove,
 * so git itself refuses when there are uncommitted or untracked changes — we
 * never discard work. Returns true only when the worktree was actually removed.
 */
export async function removeWorktreeIfClean(exec: Exec, mainRoot: string, dir: string): Promise<boolean> {
	const r = await exec("git", ["worktree", "remove", dir], { cwd: mainRoot });
	return r.code === 0;
}

/** Delete `branch` only if it is fully merged (safe `-d`); failures are ignored. */
export async function deleteBranchIfMerged(exec: Exec, mainRoot: string, branch: string): Promise<void> {
	await exec("git", ["branch", "-d", branch], { cwd: mainRoot });
}
