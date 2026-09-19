// Pin service_tier=flex on the custom `codez` provider only.
// OMP's `tier.openai` is family-wide (official OpenAI, openai-codex, OpenRouter
// OpenAI ids, and any openai-responses relay with identity.class=openai), so
// it cannot scope flex to codez. This hook writes the field on the wire.
import type { ExtensionAPI } from "@oh-my-pi/pi-coding-agent";

const CODEZ = "codez";
const FLEX = "flex";

function isRecord(value: unknown): value is Record<string, unknown> {
  return typeof value === "object" && value !== null && !Array.isArray(value);
}

export default function codezFlexTier(pi: ExtensionAPI) {
  pi.on("before_provider_request", (event, ctx) => {
    const payload = event.payload;
    if (!isRecord(payload)) return;

    if (ctx.model?.provider === CODEZ) {
      const current = payload.service_tier;
      // Keep an explicit /fast (priority) or scale request; otherwise pin flex.
      if (current === "priority" || current === "scale" || current === FLEX) return;
      return { ...payload, service_tier: FLEX };
    }

    if (!("service_tier" in payload)) return;
    const next = { ...payload };
    delete next.service_tier;
    return next;
  });
}
