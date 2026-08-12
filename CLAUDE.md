# CLAUDE.md

This file provides guidance to Claude Code (claude.ai/code) when working with code in this repository.

## Project Overview

Personal PowerShell-centered terminal configuration for Windows. This repository manages a complete terminal environment including aliases, shell completions, keybindings, and configurations for multiple tools (yazi, zellij, etc.).

## Bootstrap

Install or update the entire environment:

```powershell
Set-ExecutionPolicy -Scope Process Bypass
.\scripts\bootstrap.ps1
```

Bootstrap script behaviors (`-InstalledPackageAction`):
- **Prompt** (default): Print the already-installed list and skip updates (non-interactive)
- **Update**: Force update (`scoop update`) all installed packages
- **Reinstall**: Force uninstall + reinstall every installed package
- **Development toolchain**: Rust and Visual Studio Build Tools are installed only with `-InstallDevelopmentToolchain`

Example: `.\scripts\bootstrap.ps1 -InstalledPackageAction Update`

## Architecture

### Linking Strategy

The bootstrap script creates symlinks from user config directories back to this repo:
- PowerShell profile: `~/Documents/PowerShell/Microsoft.PowerShell_profile.ps1` → `powershell/Microsoft.PowerShell_profile.ps1`
- WezTerm config: `~/.config/wezterm` → `wezterm/` (`wezterm.lua` + `config/` + `events/`)
- Claude Code global: `~/.claude/settings.json` → `claude/settings.json` (routes through local OmniRoute)
- Claude statusline: `~/.claude/statusline-command.sh` → `claude/statusline-command.sh`
- OmniRoute: non-secret deploy docs in `omniroute/`; secrets stay in `~/.omniroute/.env` (seeded once from example)
- Neovim config: `%LocalAppData%/nvim` → `nvim/` (LazyVim-based)
- Yazi config: `%AppData%/yazi/config` → `yazi/config/`
- Zellij config: `%AppData%/Zellij/config/config.kdl` → `zellij/config.kdl`

This allows live edits to any config file in the repo to take effect immediately.

### Profile Structure (`powershell/Microsoft.PowerShell_profile.ps1`)

1. **Non-interactive shell detection**: Checks for VSCode, automation scripts, etc. via `$Host.UI.RawUI`, `$env:VSCODE_PID`, `$env:PWSH_CONFIG_QUIET` and suppresses startup prompts.

2. **Performance optimization**: Startup is timed with `[System.Diagnostics.Stopwatch]`. Zoxide is loaded by reading the real exe path from `~/scoop/shims/zoxide.shim` directly (bypassing Scoop `current` junctions) to avoid junction delays that previously caused profile hangs.

3. **Lazy completions**: zellij, pixi, and uv completions are generated on first use via `Register-ArgumentCompleter` (guarded by a `*CompletionLoaded` flag) to avoid startup overhead.

### Yazi Configuration

- `yazi.toml`: Core settings (hidden files, preview limits, git status fetchers)
- `init.lua`: Loads plugins with specific order (full-border with ROUNDED, git at order 1500)
- `plugins/`: smart-enter, toggle-pane, full-border, git
- `flavors/`: catppuccin-mocha theme

### Zellij Configuration

- Defines a `main` session (`session_name "main"`) with `attach_to_session true` and `default_layout "default"`
- Persists sessions across restarts via `session_serialization true`
- Uses `pwsh` as default shell to ensure profile is loaded in all panes

### Neovim Configuration (`nvim/`)

- LazyVim starter base; custom plugins live in `lua/plugins/` (sidekick for Claude Code, yazi.nvim, zoxide.vim)
- Custom options/autocmds in `lua/config/` (e.g. Neovide zoom persistence, explorer auto-open on VimEnter)
- Requires a C compiler for nvim-treesitter (Scoop `mingw`) and `claude` CLI in PATH for the sidekick panel

## Key Aliases and Functions

- `z` / `zi`: zoxide directory jump (provided by `zoxide init`, not an alias)
- `y`: yazi file manager (changes shell CWD after exit via temp file)
- `zs` / `zj`: zellij session attach/create
- `vi` / `vim`: nvim
- `g`: git, `gcl`: git clone, `lg`: lazygit
- `l` / `ls` / `ll` / `la` / `lt`: eza variants
- `cat` / `ccat`: bat (with/without highlighting)
- `grep`: ripgrep, `find` / `ff`: fd
- `rm`: Safe-delete reminder (use `rip` for actual deletion)

## Keybindings

- **Shell**: `Ctrl+r` (fzf history), `Ctrl+t` (fzf file insert), `Alt+c` (fzf cd), arrow keys for word navigation
- **Yazi**: `l` (smart-enter), `T` (toggle preview pane maximize/restore)

## Tools Managed via Scoop

Main: bat, bun, eza, fd, ffmpeg, fzf, imagemagick, jq, less, mingw, neovim, pixi, poppler, pwsh, resvg, rip, ripgrep, yazi, uv, zellij, zoxide, 7zip

Extras: lazygit, neovide

Versions: wezterm-nightly

Bun tools (installed after bun): opencode-ai, @openai/codex

Claude Code: Installed/upgraded via WinGet (`Anthropic.ClaudeCode`)
