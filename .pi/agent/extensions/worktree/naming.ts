const ADJECTIVES = [
	"bright", "calm", "clever", "brave", "swift", "quiet", "lucky",
	"bold", "gentle", "keen", "merry", "noble", "snug", "warm",
];

const NOUNS = [
	"fox", "owl", "lynx", "otter", "heron", "wren", "moth",
	"pine", "fern", "reef", "dune", "creek", "ember", "comet",
];

/**
 * Generate a friendly two-word name (e.g. `bright-fox`) for unnamed worktrees.
 * `rng` is injectable so the result is deterministic in tests.
 */
export function generateWorktreeName(rng: () => number = Math.random): string {
	const pick = <T>(arr: T[]): T => arr[Math.floor(rng() * arr.length)]!;
	return `${pick(ADJECTIVES)}-${pick(NOUNS)}`;
}
