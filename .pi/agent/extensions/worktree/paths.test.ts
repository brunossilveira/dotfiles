import assert from "node:assert/strict";
import { test } from "node:test";
import { getWorktreeDir, getWorktreesDir, sanitizeWorktreeName } from "./paths.ts";

test("sanitizeWorktreeName replaces path separators", () => {
	assert.equal(sanitizeWorktreeName("feature/auth"), "feature-auth");
	assert.equal(sanitizeWorktreeName("a/b/c"), "a-b-c");
});

test("sanitizeWorktreeName keeps safe characters and trims", () => {
	assert.equal(sanitizeWorktreeName("  fix_bug-123.v2  "), "fix_bug-123.v2");
});

test("sanitizeWorktreeName strips shell/traversal metacharacters", () => {
	assert.equal(sanitizeWorktreeName("a; rm -rf ~"), "a--rm--rf--");
	assert.equal(sanitizeWorktreeName("../escape"), "..-escape");
});

test("sanitizeWorktreeName falls back to 'wt' for empty or dot-only names", () => {
	assert.equal(sanitizeWorktreeName(""), "wt");
	assert.equal(sanitizeWorktreeName("   "), "wt");
	assert.equal(sanitizeWorktreeName("."), "wt");
	assert.equal(sanitizeWorktreeName(".."), "wt");
});

test("worktree dirs resolve under <repo>/.worktrees", () => {
	assert.equal(getWorktreesDir("/repo"), "/repo/.worktrees");
	assert.equal(getWorktreeDir("/repo", "feature-auth"), "/repo/.worktrees/feature-auth");
});
