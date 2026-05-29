/** Minimal structural type for pi's exec, so helpers stay decoupled and testable. */
export type Exec = (
	command: string,
	args: string[],
	options?: { cwd?: string },
) => Promise<{ code: number; stdout: string; stderr: string }>;
