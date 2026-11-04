import type { ExtensionAPI } from "@oh-my-pi/pi-coding-agent";

// Apply to Terra in every role, including subagents, without changing family tiers.
export default function terraFast(pi: ExtensionAPI) {
	pi.on("before_provider_request", (event, ctx) => {
		if (ctx.model?.provider !== "openai-codex" || ctx.model.id !== "gpt-6.1-terra") return;

		const payload = event.payload;
		if (typeof payload !== "object" || payload === null || Array.isArray(payload)) return;
		if ("service_tier" in payload && payload.service_tier === "priority") return;

		return { ...payload, service_tier: "priority" };
	});
}
