import assert from "node:assert/strict";
import { test } from "node:test";
import { generateWorktreeName } from "./naming.ts";

test("generateWorktreeName is deterministic given an rng", () => {
	assert.equal(generateWorktreeName(() => 0), "bright-fox");
});

test("generateWorktreeName picks the last entry near 1", () => {
	// 0.9999 * 14 -> index 13 in both lists
	assert.equal(generateWorktreeName(() => 0.9999), "warm-comet");
});

test("generateWorktreeName always yields a two-word slug", () => {
	for (const seed of [0, 0.25, 0.5, 0.75, 0.9999]) {
		assert.match(generateWorktreeName(() => seed), /^[a-z]+-[a-z]+$/);
	}
});
