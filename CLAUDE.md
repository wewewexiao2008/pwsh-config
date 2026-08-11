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

Bootstrap script behaviors:
- **Prompt** (default): Interactively prompt for each already-installed package
- **Update**: Force update all installed packages
- **Reinstall**: Force reinstall all installed packages
- **Development toolchain**: Rust and Visual Studio Build Tools are installed only with `-InstallDevelopmentToolchain`

Example: `.\scripts\bootstrap.ps1 -InstalledPackageAction Update`

## Architecture

### Linking Strategy

The bootstrap script creates symlinks from user config directories back to this repo:
- PowerShell profile: `~/Documents/PowerShell/Microsoft.PowerShell_profile.ps1` → `powershell/Microsoft.PowerShell_profile.ps1`
- WezTerm config: `~/.wezterm.lua` → `wezterm/wezterm.lua`
- Neovim config: `%LocalAppData%/nvim` → `nvim/` (LazyVim-based)
- Yazi config: `%AppData%/yazi/config` → `yazi/config/`
- Zellij config: `%AppData%/Zellij/config/config.kdl` → `zellij/config.kdl`

This allows live edits to any config file in the repo to take effect immediately.

### Profile Structure (`powershell/Microsoft.PowerShell_profile.ps1`)

1. **Non-interactive shell detection**: Checks for VSCode, automation scripts, etc. via `$Host.UI.RawUI`, `$env:VSCODE_PID`, `$env:PWSH_CONFIG_QUIET` and suppresses startup prompts.

2. **Performance optimization**: Startup is timed with `[System.Diagnostics.Stopwatch]`. Zoxide is loaded via direct shim path reading (lines 228-237) to avoid Scoop junction delays that previously caused profile hangs.

3. **Lazy completions**: Pixi and UV completions load on first use via `Register-ArgumentCompleter` to avoid startup overhead.

### Yazi Configuration

- `yazi.toml`: Core settings (hidden files, preview limits, git status fetchers)
- `init.lua`: Loads plugins with specific order (full-border with ROUNDED, git at order 1500)
- `plugins/`: smart-enter, toggle-pane, full-border, git
- `flavors/`: catppuccin-mocha theme

### Zellij Configuration

- Persists a `main` session across restarts via `session_serialization true`
- Uses `pwsh` as default shell to ensure profile is loaded in all panes
- Auto-attaches to existing `main` session if it exists

### Neovim Configuration (`nvim/`)

- LazyVim starter base; custom plugins live in `lua/plugins/` (sidekick for Claude Code, yazi.nvim, zoxide.vim)
- Custom options/autocmds in `lua/config/` (e.g. Neovide zoom persistence, explorer auto-open on VimEnter)
- Requires a C compiler for nvim-treesitter (Scoop `mingw`) and `claude` CLI in PATH for the sidekick panel

## Key Aliases and Functions

- `z` / `c`: zoxide directory jump
- `y`: yazi file manager (changes shell CWD after exit via temp file)
- `zs` / `zj`: zellij session attach/create
- `vi` / `vim`: nvim
- `g`: git, `gc`: git clone, `lg`: lazygit
- `l` / `ls` / `ll` / `la` / `lt`: eza variants
- `cat` / `ccat`: bat (with/without highlighting)
- `grep`: ripgrep, `find` / `ff`: fd
- `rm`: Safe-delete reminder (use `rip` for actual deletion)

## Keybindings

- **Shell**: `Ctrl+r` (fzf history), `Ctrl+t` (fzf file insert), `Alt+c` (fzf cd), arrow keys for word navigation
- **Yazi**: `l` (smart-enter), `T` (toggle preview pane maximize/restore)

## Tools Managed via Scoop

Main: bat, bun, eza, fd, ffmpeg, fzf, imagemagick, jq, less, mingw, neovim, pixi, poppler, resvg, rip, ripgrep, yazi, uv, zellij, zoxide, 7zip

Extras: lazygit, neovide

Bun tools (installed after bun): opencode-ai, qodercli, @openai/codex

Claude Code: Installed/upgraded via WinGet (`Anthropic.ClaudeCode`)
