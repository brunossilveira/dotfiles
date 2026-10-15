import { createHash } from "node:crypto";
import { execFileSync } from "node:child_process";
import { cp, lstat, mkdir, mkdtemp, readFile, realpath, rename, rm, symlink, writeFile } from "node:fs/promises";
import { homedir } from "node:os";
import { dirname, join, resolve } from "node:path";
import { fileURLToPath } from "node:url";

const directory = dirname(fileURLToPath(import.meta.url));
const repo = resolve(directory, "../..");

// Only executable plugin code is deployed. Shared prompts and hooks stay shared.
export async function deployPlugin({
  source = join(directory, "plugins/shared-harness"),
  config = join(process.env.XDG_CONFIG_HOME || join(homedir(), ".config"), "opencode"),
  data = join(process.env.XDG_DATA_HOME || join(homedir(), ".local/share"), "opencode/dotfiles-plugins"),
  checkOnly = false,
} = {}) {
  // Stage on the release filesystem so publishing can use an atomic rename.
  await mkdir(data, { recursive: true });
  const stage = await mkdtemp(join(data, ".candidate-"));
  const temporaryLink = join(config, `.shared-harness-${process.pid}-${Date.now()}`);
  try {
    for (const file of ["index.js", "package.json"]) await cp(join(source, file), join(stage, file));
    const options = { cwd: repo, stdio: "pipe", timeout: 120_000 };
    const env = { ...process.env, OPENCODE_HARNESS_PLUGIN: join(stage, "index.js") };
    // A nested Node test runner must not inherit the parent's runner context.
    delete env.NODE_TEST_CONTEXT;
    const compiler = join(directory, "node_modules/typescript/bin/tsc");
    await realpath(compiler).catch(() => {
      throw new Error("Install validation tools first: npm ci --prefix config/opencode --ignore-scripts");
    });
    await writeFile(join(stage, "tsconfig.json"), JSON.stringify({
      extends: join(directory, "tsconfig.json"),
      compilerOptions: {
        typeRoots: [join(directory, "node_modules/@types")],
        paths: { "@opencode/plugin": [join(directory, "node_modules/@opencode/plugin/dist/promise/index.d.ts")] },
      },
      files: [join(stage, "index.js")],
    }));
    execFileSync(process.execPath, [compiler, "--project", join(stage, "tsconfig.json")], options);
    execFileSync(process.execPath, ["--check", join(stage, "index.js")], options);
    execFileSync(process.execPath, ["--test", join(directory, "tests/shared-harness.test.mjs")], {
      ...options, env,
    });
    execFileSync("python3", ["-m", "unittest", "discover", "-s", ".claude/hooks/tests"], options);
    if (checkOnly) return { checked: true };

    await rm(join(stage, "tsconfig.json"));

    const hash = createHash("sha256");
    for (const file of ["index.js", "package.json"]) hash.update(await readFile(join(stage, file)));
    const release = join(data, hash.digest("hex"));
    // Never overwrite an existing release: running sessions may still use it.
    try {
      await realpath(release);
    } catch (error) {
      if (error.code !== "ENOENT") throw error;
      await rename(stage, release);
    }
    const target = join(config, "plugins/shared-harness.js");
    await mkdir(dirname(target), { recursive: true });
    const existing = await lstat(target).catch(error => {
      if (error.code !== "ENOENT") throw error;
    });
    if (existing && !existing.isSymbolicLink()) throw new Error(`Refusing to replace non-symlink: ${target}`);
    if (existing && await realpath(target) === join(release, "index.js")) return { release, unchanged: true };
    await symlink(join(release, "index.js"), temporaryLink);
    // rename replaces only the symlink, not its target. No half-written live code.
    await rename(temporaryLink, target);
    return { release };
  } finally {
    await rm(stage, { recursive: true, force: true });
    await rm(temporaryLink, { force: true });
  }
}

if (process.argv[1] && resolve(process.argv[1]) === fileURLToPath(import.meta.url)) {
  try {
    const args = process.argv.slice(2);
    if (args.some(arg => arg !== "--check")) throw new Error("Usage: node config/opencode/deploy-plugin.mjs [--check]");
    console.log(await deployPlugin({ checkOnly: args.includes("--check") }));
  } catch (error) {
    console.error(error.stdout?.toString() || error.stderr?.toString() || error.message);
    process.exitCode = 1;
  }
}
