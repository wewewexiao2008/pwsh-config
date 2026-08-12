# OmniRoute (non-secret)

OmniRoute keeps API keys and runtime state under `~/.omniroute/` (SQLite + `.env`).
This repo only stores **deploy hints** so another machine can recreate the same topology.

## Files

| File | Purpose |
|------|---------|
| `.env.example` | Local secret placeholders (`STORAGE_ENCRYPTION_KEY`, …) |
| `providers.manifest.json` | Intended providers + Claude model routing (no keys) |

## New machine

1. Install: `npm i -g omniroute` (or keep current global version).
2. Copy `.env.example` → `~/.omniroute/.env`, generate `STORAGE_ENCRYPTION_KEY` (`openssl rand -hex 32`).
3. Start OmniRoute daemon (default API `http://127.0.0.1:20128`).
4. In the dashboard, add providers from `providers.manifest.json` and paste **machine-local** API keys.
5. Block free junk aggregators: `theoldllm`, `tllm` (or equivalent UI toggle).
6. Run `pwsh-config` bootstrap so `~/.claude/settings.json` points Claude Code at the gateway.

## Exporting a live bundle later

With OmniRoute authenticated locally:

```powershell
omniroute sync bundle .\omniroute\bundle.json --include settings,combos,providers,policies,skills
```

Do **not** commit bundles that include `keys`. Prefer re-import on the new machine after adding keys in the UI.

## Related

Claude Code global settings live in `claude/settings.json` (linked to `~/.claude/settings.json` by bootstrap).
