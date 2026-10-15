import assert from "node:assert/strict";
import { cp, mkdtemp, readFile, realpath, rm, writeFile } from "node:fs/promises";
import { tmpdir } from "node:os";
import { join } from "node:path";
import { fileURLToPath } from "node:url";
import test from "node:test";
import { deployPlugin } from "../deploy-plugin.mjs";

test("activation isolates live code and rejects the original crashing regression", async t => {
  const root = await mkdtemp(join(tmpdir(), "opencode-deploy-test-"));
  t.after(() => rm(root, { recursive: true, force: true }));
  const source = join(root, "source");
  await cp(fileURLToPath(new URL("../plugins/shared-harness", import.meta.url)), source, { recursive: true });
  const options = { source, config: join(root, "config"), data: join(root, "releases") };
  const { release } = await deployPlugin(options);
  const live = join(options.config, "plugins/shared-harness.js");
  const goodCode = await readFile(live, "utf8");

  // A syntactically valid plugin that fails only when its context hook executes.
  await writeFile(join(source, "index.js"), `export default {
    id: "dotfiles.shared-harness",
    /** @param {import('@opencode/plugin').Plugin.Context} ctx */
    async setup(ctx) {
      await ctx.session.hook("context", () => { throw new ReferenceError("cwd is not defined"); });
    }
  };`);
  assert.equal(await readFile(live, "utf8"), goodCode, "editing source must not hot-reload live code");
  await assert.rejects(deployPlugin(options), error => /cwd is not defined/.test(error.stdout?.toString()));
  assert.equal(await realpath(live), join(release, "index.js"));
  assert.equal(await readFile(live, "utf8"), goodCode, "a rejected candidate must leave the active release intact");

  await writeFile(join(source, "index.js"), `export default {
    id: "dotfiles.shared-harness",
    /** @param {import('@opencode/plugin').Plugin.Context} ctx */
    async setup(ctx) {
      await ctx.session.hook("context", event => {
        event.system.push({ type: "text", text: String(cwd) });
      });
    }
  };`);
  await assert.rejects(deployPlugin(options), error => /Cannot find name 'cwd'/.test(error.stdout?.toString()));
  assert.equal(await realpath(live), join(release, "index.js"));
});
