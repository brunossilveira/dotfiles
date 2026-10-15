import { execFile } from "node:child_process";
import { readFile, realpath, stat } from "node:fs/promises";
import { homedir } from "node:os";
import { join, resolve } from "node:path";

/** @param {string} file @param {string[]} args @param {object} payload @param {NodeJS.ProcessEnv} env */
function runHook(file, args, payload, env) {
  return new Promise((resolve, reject) => {
    const child = execFile(file, args, { env, timeout: 15_000, maxBuffer: 1024 * 1024 }, (error, stdout) => {
      if (error) return reject(error);
      try {
        resolve(stdout.trim() ? JSON.parse(stdout) : undefined);
      } catch (error) {
        reject(error);
      }
    });
    child.stdin?.on("error", reject);
    child.stdin?.end(JSON.stringify(payload));
  });
}

/** @param {unknown} input @returns {Record<string, any>} */
function argsOf(input) {
  return input && typeof input === "object" ? input : {};
}

/** @param {string} tool @param {Record<string, any>} input */
function editedPaths(tool, input) {
  if (tool === "edit" || tool === "write") return [input.path];
  if (tool !== "patch") return [];
  return [...String(input.patchText).matchAll(/^\*\*\* (?:Add|Update|Delete) File: (.+)$|^\*\*\* Move to: (.+)$/gm)]
    .map(match => match[1] || match[2]);
}

export default {
  id: "dotfiles.shared-harness",
  /** @param {import('@opencode/plugin').Plugin.Context} ctx */
  async setup(ctx) {
    const home = typeof ctx.options.home === "string" ? ctx.options.home : homedir();
    const hooks = join(home, ".claude", "hooks");
    const env = { ...process.env };
    if (typeof ctx.options.stateDirectory === "string") env.AGENT_VERIFY_ON_STOP_STATE_DIR = ctx.options.stateDirectory;
    /** @type {Map<string, Set<string>>} */
    const reads = new Map();
    /** @param {string} sessionID */
    const directory = async sessionID => {
      const session = await ctx.session.get({ sessionID });
      return session.location.directory;
    };

    // Prompts remain owned by PI; only harness metadata is translated here.
    const profiles = await Promise.all(["explore", "plan", "reviewer", "debugger"].map(async id => {
      const text = await readFile(join(home, ".pi", "agent", "agents", `${id}.md`), "utf8");
      const [, header, body] = text.split(/^---\s*$/m);
      const description = header.match(/^description:\s*(.+)$/m)?.[1];
      const tools = header.match(/^tools:\s*(.+)$/m)?.[1].split(/,\s*/) || [];
      return { id, body: body.trim(), description, tools };
    }));
    await ctx.agent.transform(editor => {
      for (const profile of profiles) editor.update(profile.id, agent => {
        agent.system = profile.body;
        agent.description = profile.description;
        agent.mode = profile.id === "plan" ? "all" : "subagent";
        if (!profile.tools.includes("edit") && !profile.tools.includes("write")) {
          agent.permissions.push({ action: "edit", resource: "*", effect: "deny" });
        }
        if (!profile.tools.includes("bash")) {
          agent.permissions.push({ action: "shell", resource: "*", effect: "deny" });
        }
      });
    });

    await ctx.permission.hook("evaluate", async event => {
      if (event.action !== "shell") return;
      for (const command of event.resources) {
        const result = await runHook("jq", ["-c", "-f", join(hooks, "deny-rm-rf.jq")], {
          tool_input: { command },
        }, env);
        if (result?.hookSpecificOutput?.permissionDecision === "deny") {
          event.effect = "deny";
          event.message = result.hookSpecificOutput.permissionDecisionReason;
          return;
        }
      }
    });

    await ctx.tool.hook("execute.before", async event => {
      const paths = editedPaths(event.tool, argsOf(event.input));
      if (!paths.length) return;
      const cwd = await directory(event.sessionID);
      for (const path of paths) {
        const absolute = resolve(cwd, path);
        let canonical;
        try {
          canonical = await realpath(absolute);
        } catch (error) {
          if (/** @type {NodeJS.ErrnoException} */ (error).code === "ENOENT") continue;
          throw error;
        }
        if (!reads.get(event.sessionID)?.has(canonical)) {
          throw new Error(`You must read "${path}" before editing it. Use the read tool first.`);
        }
      }
    });

    await ctx.tool.hook("execute.after", async event => {
      if (event.status !== "completed") return;
      const input = argsOf(event.input);
      if (!["read", "edit", "write", "patch", "shell"].includes(event.tool)) return;
      const cwd = await directory(event.sessionID);
      if (event.tool === "read") {
        const path = resolve(cwd, input.path);
        if ((await stat(path)).isFile()) {
          const seen = reads.get(event.sessionID) || new Set();
          seen.add(await realpath(path));
          reads.set(event.sessionID, seen);
        }
        return;
      }
      const paths = editedPaths(event.tool, input);
      if (event.tool !== "shell" && !paths.length) return;
      // Translate native tool events to the shared verifier's existing ledger protocol.
      // Background shell admission is not proof that a command has succeeded.
      if (event.tool === "shell" && (input.background || event.result.metadata?.exit !== 0)) return;
      await runHook("python3", [join(hooks, "verify-on-stop.py")], {
        hook_event_name: "PostToolUse",
        session_id: `opencode-${event.sessionID}`,
        cwd,
        tool_name: event.tool === "shell" ? "Bash" : "apply_patch",
        tool_input: { command: event.tool === "shell" ? input.command : paths.map(path => `*** Update File: ${path}`).join("\n") },
        tool_response: { exit_code: 0 },
      }, env);
    });

    // V2 has no Stop interception API. Reuse the verifier before model responses,
    // without claiming that this can block the session from stopping.
    await ctx.session.hook("context", async event => {
      try {
        const result = await runHook("python3", [join(hooks, "verify-on-stop.py")], {
          hook_event_name: "Stop",
          session_id: `opencode-${event.sessionID}`,
          cwd: await directory(event.sessionID),
        }, env);
        if (result?.reason) event.system.push({ type: "text", text: result.reason });
      } catch (error) {
        // A reminder is advisory. Its failure must not prevent model requests.
        const message = error instanceof Error ? error.message : String(error);
        console.error(`[shared-harness] Verification reminder unavailable: ${message}`);
        event.system.push({
          type: "text",
          text: `Verification reminder unavailable: ${message}. Tell the user this check failed; do not claim verification based on it.`,
        });
      }
    });
  },
};
