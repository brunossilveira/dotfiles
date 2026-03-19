/**
 * Web Search & Fetch Extension
 *
 * Provides two tools:
 *   - web_search: Search the web via Jina Search (free, no API key)
 *   - web_fetch: Fetch a URL and return clean markdown via Jina Reader (free, no API key)
 *
 * Uses Jina's free APIs under the hood. No dependencies beyond built-in fetch().
 */

import type { ExtensionAPI } from "@mariozechner/pi-coding-agent";
import { Type } from "@sinclair/typebox";

const MAX_CONTENT_LENGTH = 30000;
const JINA_SEARCH_URL = "https://s.jina.ai/";
const JINA_READER_URL = "https://r.jina.ai/";

function truncate(text: string, max: number): string {
	if (text.length <= max) return text;
	return text.slice(0, max) + "\n\n[... truncated]";
}

export default function (pi: ExtensionAPI) {
	pi.registerTool({
		name: "web_search",
		label: "Web Search",
		description:
			"Search the web for information. Returns search results with titles, URLs, and snippets. Use this to find relevant pages, then use web_fetch to read specific ones.",
		parameters: Type.Object({
			query: Type.String({ description: "The search query" }),
			count: Type.Optional(Type.Number({ description: "Number of results to return (default: 5, max: 10)" })),
		}),
		promptGuidelines: [
			"Use web_search to find information on the web. Do not use bash with curl for web searches.",
			"After searching, use web_fetch to read specific pages from the results.",
		],

		async execute(_toolCallId, params, signal) {
			const { query, count } = params;
			const numResults = Math.min(count ?? 5, 10);

			try {
				const response = await fetch(JINA_SEARCH_URL + encodeURIComponent(query), {
					headers: {
						Accept: "application/json",
						"X-Retain-Images": "none",
						"X-No-Cache": "false",
					},
					signal,
				});

				if (!response.ok) {
					throw new Error(`Search failed: ${response.status} ${response.statusText}`);
				}

				const data = (await response.json()) as { data?: Array<{ title: string; url: string; description: string; content?: string }> };

				if (!data.data || data.data.length === 0) {
					return { content: [{ type: "text", text: `No results found for: ${query}` }] };
				}

				const results = data.data.slice(0, numResults);
				const formatted = results
					.map((r, i) => `${i + 1}. **${r.title}**\n   ${r.url}\n   ${r.description || ""}`)
					.join("\n\n");

				return {
					content: [{ type: "text", text: `Search results for: ${query}\n\n${formatted}` }],
				};
			} catch (error: any) {
				if (error.name === "AbortError") throw error;
				return {
					content: [{ type: "text", text: `Search error: ${error.message}` }],
					isError: true,
				};
			}
		},
	});

	pi.registerTool({
		name: "web_fetch",
		label: "Web Fetch",
		description:
			"Fetch the content of a URL and return it as clean, readable markdown. Works with web pages, PDFs, and other documents. Content is truncated if too large.",
		parameters: Type.Object({
			url: Type.String({ description: "The URL to fetch" }),
		}),
		promptGuidelines: [
			"Use web_fetch to read the content of a specific URL. Do not use bash with curl to fetch web pages.",
		],

		async execute(_toolCallId, params, signal) {
			const { url } = params;

			try {
				const response = await fetch(JINA_READER_URL + url, {
					headers: {
						Accept: "text/plain",
						"X-Retain-Images": "none",
						"X-No-Cache": "false",
					},
					signal,
				});

				if (!response.ok) {
					throw new Error(`Fetch failed: ${response.status} ${response.statusText}`);
				}

				const text = await response.text();

				if (!text.trim()) {
					return { content: [{ type: "text", text: `No content found at: ${url}` }] };
				}

				return {
					content: [{ type: "text", text: truncate(text.trim(), MAX_CONTENT_LENGTH) }],
				};
			} catch (error: any) {
				if (error.name === "AbortError") throw error;
				return {
					content: [{ type: "text", text: `Fetch error: ${error.message}` }],
					isError: true,
				};
			}
		},
	});
}
