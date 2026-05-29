import assert from "node:assert/strict";
import { test } from "node:test";
import { parseWorktreeInclude } from "./include.ts";

test("parseWorktreeInclude keeps real patterns", () => {
	assert.deepEqual(parseWorktreeInclude(".env\n.env.local\nconfig/secrets.json\n"), [
		".env",
		".env.local",
		"config/secrets.json",
	]);
});

test("parseWorktreeInclude drops comments and blank lines", () => {
	const content = "# secrets\n\n.env\n   \n# another\n.env.local";
	assert.deepEqual(parseWorktreeInclude(content), [".env", ".env.local"]);
});

test("parseWorktreeInclude trims surrounding whitespace", () => {
	assert.deepEqual(parseWorktreeInclude("  .env  \n\t.env.local\t"), [".env", ".env.local"]);
});

test("parseWorktreeInclude returns empty for blank input", () => {
	assert.deepEqual(parseWorktreeInclude("\n\n# only a comment\n"), []);
});
