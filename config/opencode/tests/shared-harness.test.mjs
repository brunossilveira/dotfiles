import assert from "node:assert/strict";
import { mkdtemp, mkdir, readFile, rm, writeFile } from "node:fs/promises";
import { tmpdir } from "node:os";
import { join } from "node:path";
import { fileURLToPath, pathToFileURL } from "node:url";
import test from "node:test";

const { default: plugin } = await import(process.env.OPENCODE_HARNESS_PLUGIN
  ? pathToFileURL(process.env.OPENCODE_HARNESS_PLUGIN).href
  : "../plugins/shared-harness/index.js");
const repo = fileURLToPath(new URL("../../../", import.meta.url));

async function harness(t) {
  // The shared verifier deliberately ignores files under /tmp.
  const cwd = await mkdtemp(join(repo, ".opencode-test-"));
  const state = await mkdtemp(join(tmpdir(), "opencode-verifier-"));
  t.after(() => Promise.all([rm(cwd, { recursive: true }), rm(state, { recursive: true })]));
  await mkdir(join(cwd, ".git"));
  await writeFile(join(cwd, "pyproject.toml"), "");
  const hooks = {};
  let directory = cwd;
  let lookupError;
  const agents = new Map(["explore", "plan", "reviewer", "debugger"].map(id => [id, { id, permissions: [] }]));
  const ctx = {
    location: { directory: cwd },
    options: { home: repo, stateDirectory: state },
    agent: { transform: async fn => fn({ update: (id, fn) => fn(agents.get(id)) }) },
    tool: { hook: async (name, fn) => { hooks[name] = fn; } },
    permission: { hook: async (name, fn) => { hooks[`permission.${name}`] = fn; } },
    session: {
      get: async () => {
        if (lookupError) throw lookupError;
        return { location: { directory } };
      },
      hook: async (name, fn) => { hooks[`session.${name}`] = fn; },
    },
  };
  await plugin.setup(ctx);
  return {
    cwd, hooks, agents,
    move: path => { directory = path; },
    failLookup: error => { lookupError = error; },
  };
}

test("PI profiles supply the actual agent prompts and read-only restrictions", async t => {
  const { agents } = await harness(t);
  const source = await readFile(join(repo, ".pi/agent/agents/reviewer.md"), "utf8");
  assert.equal(agents.get("reviewer").system.trim(), source.split("---")[2].trim());
  assert.equal(agents.get("reviewer").mode, "subagent");
  assert.deepEqual(agents.get("reviewer").permissions.filter(r => r.action === "edit"), [
    { action: "edit", resource: "*", effect: "deny" },
  ]);
  assert.equal(agents.get("plan").mode, "all");
  assert.equal(agents.get("debugger").permissions.find(r => r.action === "edit"), undefined);
});

test("the existing jq guard rejects dangerous commands but permits ordinary ones", async t => {
  const { hooks } = await harness(t);
  const denied = { action: "shell", resources: ["rm -rf build"], effect: "allow" };
  await hooks["permission.evaluate"](denied);
  assert.equal(denied.effect, "deny");
  assert.match(denied.message, /Refusing/);
  const allowed = { action: "shell", resources: ["git status"], effect: "ask" };
  await hooks["permission.evaluate"](allowed);
  assert.equal(allowed.effect, "ask");
});

test("edits require a successful read in the same session; new files are allowed", async t => {
  const { cwd, hooks } = await harness(t);
  const path = join(cwd, "app.py");
  await writeFile(path, "pass\n");
  const edit = { tool: "patch", sessionID: "a", input: { patchText: "*** Begin Patch\n*** Update File: app.py\n@@\n-pass\n+print(1)\n*** End Patch" } };
  await assert.rejects(hooks["execute.before"](edit), /read.*app.py/i);
  await hooks["execute.after"]({ tool: "read", sessionID: "a", input: { path }, status: "error" });
  await assert.rejects(hooks["execute.before"](edit), /read/i);
  await hooks["execute.after"]({ tool: "read", sessionID: "a", input: { path }, status: "completed", result: { content: "pass" } });
  await hooks["execute.before"](edit);
  await assert.rejects(hooks["execute.before"]({ ...edit, sessionID: "b" }), /read/i);
  await hooks["execute.before"]({ tool: "write", sessionID: "b", input: { path: "new.py", content: "pass" } });
});

test("the shared Python verifier tracks edits, ignores failed checks, and clears on success", async t => {
  const { hooks } = await harness(t);
  await hooks["execute.after"]({ tool: "write", sessionID: "verified", input: { path: "app.py" }, status: "completed", result: { content: "written" } });
  const context = () => ({ sessionID: "verified", system: [] });
  const pending = context();
  await hooks["session.context"](pending);
  assert.match(pending.system.map(p => p.text).join("\n"), /app.py/);
  await hooks["execute.after"]({ tool: "shell", sessionID: "verified", input: { command: "pytest" }, status: "completed", result: { content: "1 failed", metadata: { exit: 1 } } });
  const failed = context();
  await hooks["session.context"](failed);
  assert.match(failed.system.map(p => p.text).join("\n"), /app.py/);
  await hooks["execute.after"]({ tool: "shell", sessionID: "verified", input: { command: "pytest" }, status: "completed", result: { content: "1 passed", metadata: { exit: 0 } } });
  const passed = context();
  await hooks["session.context"](passed);
  assert.equal(passed.system.some(p => /Unverified paths/.test(p.text)), false);
});

test("read enforcement follows a session moved into another directory", async t => {
  const { cwd, hooks, move } = await harness(t);
  const destination = join(cwd, "worktree");
  await mkdir(destination);
  await writeFile(join(destination, "existing.py"), "pass\n");
  move(destination);
  await assert.rejects(hooks["execute.before"]({
    tool: "write", sessionID: "moved", input: { path: "existing.py", content: "changed" },
  }), /read/i);
});

test("the pre-response hook runs on an untouched session", async t => {
  const { hooks } = await harness(t);
  const event = { sessionID: "untouched", system: [] };
  await hooks["session.context"](event);
  assert.deepEqual(event.system, []);
});

test("an advisory verifier failure is visible without preventing a response", async t => {
  const { hooks, failLookup } = await harness(t);
  failLookup(new Error("session lookup unavailable"));
  const event = { sessionID: "unavailable", system: [] };
  await hooks["session.context"](event);
  assert.match(event.system[0].text, /Verification reminder unavailable.*session lookup unavailable/);
  assert.match(event.system[0].text, /Tell the user/);
});
