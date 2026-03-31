/**
 * Custom UI Extension
 *
 * - Minimal header with project name
 * - Powerline footer: git branch, model, tokens, cost, turn status
 * - Titlebar spinner during agent activity
 */

import path from "node:path";
import type { AssistantMessage } from "@mariozechner/pi-ai";
import type { ExtensionAPI, ExtensionContext } from "@mariozechner/pi-coding-agent";
import { truncateToWidth, visibleWidth } from "@mariozechner/pi-tui";

// --- Powerline characters (Nerd Font) ---

const PL = {
	rightFilled: "\uE0B0", // left group end cap
	rightThin: "\uE0B1", //   separator within left group
	leftFilled: "\uE0B2", //  right group end cap
	leftThin: "\uE0B3", //    separator within right group
};

// --- Nerd Font icons ---

const ICON = {
	branch: "\uE0A0", //  git branch
	model: "\uF0E7", //  lightning bolt
	tokens: "\uF0C9", //  bars
	cost: "\uF155", //  dollar
	turn: "\uF192", //  dot-circle
	folder: "\uF115", //  folder
};

// --- ANSI helpers ---

function fg(r: number, g: number, b: number, text: string): string {
	return `\x1b[38;2;${r};${g};${b}m${text}\x1b[0m`;
}

function fgBg(fgR: number, fgG: number, fgB: number, bgR: number, bgG: number, bgB: number, text: string): string {
	return `\x1b[38;2;${fgR};${fgG};${fgB};48;2;${bgR};${bgG};${bgB}m${text}\x1b[0m`;
}

function bgOnly(r: number, g: number, b: number, text: string): string {
	return `\x1b[48;2;${r};${g};${b}m${text}\x1b[0m`;
}

// --- Segment builder ---

interface Segment {
	text: string;
	fgColor: [number, number, number];
	bgColor: [number, number, number];
}

// Colors (muted, dark palette)
const C = {
	bg1: [50, 50, 65] as [number, number, number], //    segment bg (dark blue-gray)
	bg2: [40, 40, 55] as [number, number, number], //    alternate segment bg
	text: [200, 200, 210] as [number, number, number], // default text
	accent: [100, 180, 240] as [number, number, number], // blue accent
	green: [120, 190, 120] as [number, number, number], // git, success
	yellow: [220, 190, 100] as [number, number, number], // cost
	muted: [140, 140, 160] as [number, number, number], // tokens, model
	orange: [220, 150, 80] as [number, number, number], // turn active
};

function renderPowerline(segments: Segment[], width: number, direction: "left" | "right"): string {
	if (segments.length === 0) return "";

	let result = "";

	if (direction === "left") {
		for (let i = 0; i < segments.length; i++) {
			const seg = segments[i];
			const [fr, fg2, fb] = seg.fgColor;
			const [br, bg2, bb] = seg.bgColor;

			// Segment content
			result += fgBg(fr, fg2, fb, br, bg2, bb, ` ${seg.text} `);

			// Separator: filled triangle with fg = this segment's bg, against next segment's bg (or terminal default)
			if (i < segments.length - 1) {
				const next = segments[i + 1];
				result += fgBg(br, bg2, bb, next.bgColor[0], next.bgColor[1], next.bgColor[2], PL.rightFilled);
			} else {
				// End cap: triangle pointing right with fg = segment bg, against terminal default
				result += fg(br, bg2, bb, PL.rightFilled);
			}
		}
	} else {
		for (let i = 0; i < segments.length; i++) {
			const seg = segments[i];
			const [fr, fg2, fb] = seg.fgColor;
			const [br, bg2, bb] = seg.bgColor;

			// Start cap: filled triangle pointing left
			if (i === 0) {
				result += fg(br, bg2, bb, PL.leftFilled);
			} else {
				const prev = segments[i - 1];
				result += fgBg(br, bg2, bb, prev.bgColor[0], prev.bgColor[1], prev.bgColor[2], PL.leftFilled);
			}

			// Segment content
			result += fgBg(fr, fg2, fb, br, bg2, bb, ` ${seg.text} `);
		}
	}

	return result;
}

// --- Utilities ---

const BRAILLE_FRAMES = ["\u280B", "\u2819", "\u2839", "\u2838", "\u283C", "\u2834", "\u2826", "\u2827", "\u2807", "\u280F"];

function fmt(n: number): string {
	if (n < 1000) return `${n}`;
	if (n < 10000) return `${(n / 1000).toFixed(1)}k`;
	if (n < 1000000) return `${Math.round(n / 1000)}k`;
	return `${(n / 1000000).toFixed(1)}M`;
}

function getBaseTitle(pi: ExtensionAPI): string {
	const cwd = path.basename(process.cwd());
	const session = pi.getSessionName();
	return session ? `\u03C0 ${session} \u2014 ${cwd}` : `\u03C0 ${cwd}`;
}

// --- Extension ---

export default function (pi: ExtensionAPI) {
	let turnCount = 0;
	let agentActive = false;
	let spinnerTimer: ReturnType<typeof setInterval> | null = null;
	let spinnerFrame = 0;

	// --- Titlebar spinner ---

	function stopSpinner(ctx: ExtensionContext) {
		if (spinnerTimer) {
			clearInterval(spinnerTimer);
			spinnerTimer = null;
		}
		spinnerFrame = 0;
		ctx.ui.setTitle(getBaseTitle(pi));
	}

	function startSpinner(ctx: ExtensionContext) {
		stopSpinner(ctx);
		spinnerTimer = setInterval(() => {
			const frame = BRAILLE_FRAMES[spinnerFrame % BRAILLE_FRAMES.length];
			ctx.ui.setTitle(`${frame} ${getBaseTitle(pi)}`);
			spinnerFrame++;
		}, 80);
	}

	pi.on("agent_start", async (_event, ctx) => {
		agentActive = true;
		startSpinner(ctx);
	});

	pi.on("agent_end", async (_event, ctx) => {
		agentActive = false;
		stopSpinner(ctx);
	});

	pi.on("session_shutdown", async (_event, ctx) => {
		stopSpinner(ctx);
	});

	// --- Turn counter ---

	pi.on("turn_start", async () => {
		turnCount++;
	});

	pi.on("session_switch", async (event) => {
		if (event.reason === "new") turnCount = 0;
	});

	// --- Header + Footer ---

	pi.on("session_start", async (_event, ctx) => {
		if (!ctx.hasUI) return;

		const cwd = path.basename(process.cwd());

		// Header
		ctx.ui.setHeader((_tui, theme) => ({
			invalidate() {},
			render(width: number): string[] {
				const title = theme.fg("accent", "\u03C0 ") + theme.fg("text", cwd);
				const line = theme.fg("border", "\u2500".repeat(width));
				return ["", ` ${title}`, line];
			},
		}));

		// Powerline footer
		ctx.ui.setFooter((tui, theme, footerData) => {
			const unsub = footerData.onBranchChange(() => tui.requestRender());

			return {
				dispose: unsub,
				invalidate() {},
				render(width: number): string[] {
					// --- Left segments ---
					const leftSegs: Segment[] = [];

					// Git branch
					const branch = footerData.getGitBranch();
					if (branch) {
						leftSegs.push({
							text: `${ICON.branch} ${branch}`,
							fgColor: C.green,
							bgColor: C.bg1,
						});
					}

					// Turn status
					const turnIcon = agentActive ? ICON.turn : "\u2713";
					const turnColor = agentActive ? C.orange : C.green;
					leftSegs.push({
						text: `${turnIcon} ${turnCount > 0 ? `Turn ${turnCount}` : "Ready"}`,
						fgColor: turnColor,
						bgColor: leftSegs.length % 2 === 0 ? C.bg1 : C.bg2,
					});

					// --- Right segments ---
					const rightSegs: Segment[] = [];

					// Tokens
					let input = 0;
					let output = 0;
					let cost = 0;
					for (const e of ctx.sessionManager.getBranch()) {
						if (e.type === "message" && e.message.role === "assistant") {
							const m = e.message as AssistantMessage;
							input += m.usage.input;
							output += m.usage.output;
							cost += m.usage.cost.total;
						}
					}

					if (input > 0 || output > 0) {
						rightSegs.push({
							text: `\u2191${fmt(input)} \u2193${fmt(output)}`,
							fgColor: C.muted,
							bgColor: C.bg2,
						});
					}

					// Cost
					if (cost > 0) {
						rightSegs.push({
							text: `${ICON.cost}${cost.toFixed(3)}`,
							fgColor: C.yellow,
							bgColor: C.bg1,
						});
					}

					// Model
					const model = ctx.model?.id || "";
					if (model) {
						rightSegs.push({
							text: `${ICON.model} ${model}`,
							fgColor: C.accent,
							bgColor: rightSegs.length % 2 === 0 ? C.bg2 : C.bg1,
						});
					}

					// --- Render ---
					const leftStr = renderPowerline(leftSegs, width, "left");
					const rightStr = renderPowerline(rightSegs, width, "right");

					const leftWidth = visibleWidth(leftStr);
					const rightWidth = visibleWidth(rightStr);
					const gap = Math.max(1, width - leftWidth - rightWidth);
					const fill = theme.fg("border", "\u2500".repeat(gap));

					return [truncateToWidth(leftStr + fill + rightStr, width)];
				},
			};
		});

		// Set initial title
		ctx.ui.setTitle(getBaseTitle(pi));
	});
}
