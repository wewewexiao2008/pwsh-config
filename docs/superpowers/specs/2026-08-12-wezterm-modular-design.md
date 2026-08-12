# WezTerm modular config design

Date: 2026-08-12  
Status: approved

## Goal

Split the single-file WezTerm config into Kevin-style modules **without changing behavior**.

## Decisions

- Scope: keep current features only (no Kevin backdrops / Leader / WSL domains).
- Style: each module exports `apply_to_config(config)` or `setup()`.
- Deploy: junction/symlink `~/.config/wezterm` → repo `wezterm/`; remove legacy `~/.wezterm.lua`.

## Layout

```
wezterm/
  wezterm.lua
  config/appearance.lua
  config/general.lua
  config/bindings.lua
  config/plugins.lua
  events/tab-title.lua
  events/status.lua
```

## Bootstrap

- Link directory with existing `New-DirectoryLink`.
- Delete `~/.wezterm.lua` when it is our previous symlink/loader so `.config/wezterm` is used.
- Update README / CLAUDE.md / AGENTS.md link docs.
