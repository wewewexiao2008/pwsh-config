local wezterm = require 'wezterm'
local act = wezterm.action
local mux = wezterm.mux

local resurrect = wezterm.plugin.require 'https://github.com/YedPool/resurrect.wezterm'
local workspace_switcher = wezterm.plugin.require 'https://github.com/MLFlexer/smart_workspace_switcher.wezterm'

local config = wezterm.config_builder()

-- Remember last window size + position across launches (local file, no remote plugin).
-- WezTerm exposes set_position but not get_position; on Windows we read the
-- foreground window rect via PowerShell/user32 after resize settles / on blur.
local window_geometry_cache = wezterm.home_dir .. '/.local/share/wezterm/window-geometry.json'
local geometry_save_token = 0

local function read_window_geometry()
  local file = io.open(window_geometry_cache, 'r')
  if not file then
    return nil
  end
  local raw = file:read '*a'
  file:close()
  if not raw or raw == '' then
    return nil
  end
  local ok, data = pcall(wezterm.json_parse, raw)
  if not ok or type(data) ~= 'table' then
    return nil
  end
  local width = tonumber(data.pixel_width)
  local height = tonumber(data.pixel_height)
  local x = tonumber(data.x)
  local y = tonumber(data.y)
  if not width or not height or width < 200 or height < 200 then
    return nil
  end
  return {
    pixel_width = width,
    pixel_height = height,
    x = x,
    y = y,
  }
end

local function read_window_position_windows()
  local ps = [[
Add-Type -TypeDefinition @'
using System;
using System.Runtime.InteropServices;
public class WezWinPos {
  [DllImport("user32.dll")] public static extern IntPtr GetForegroundWindow();
  [DllImport("user32.dll")] public static extern bool GetWindowRect(IntPtr hWnd, out RECT lpRect);
  [StructLayout(LayoutKind.Sequential)] public struct RECT { public int Left; public int Top; public int Right; public int Bottom; }
}
'@
$h = [WezWinPos]::GetForegroundWindow()
$r = New-Object WezWinPos+RECT
if ([WezWinPos]::GetWindowRect($h, [ref]$r)) { Write-Output ("{0},{1}" -f $r.Left, $r.Top) }
]]
  local ok, stdout = wezterm.run_child_process {
    'powershell.exe',
    '-NoProfile',
    '-NonInteractive',
    '-Command',
    ps,
  }
  if not ok or not stdout then
    return nil, nil
  end
  local x, y = stdout:match '(-?%d+),(-?%d+)'
  return tonumber(x), tonumber(y)
end

local function write_window_geometry(window)
  local dims = window:get_dimensions()
  if dims.is_full_screen then
    return
  end

  local existing = read_window_geometry() or {}
  local x, y = existing.x, existing.y
  if wezterm.target_triple:find 'windows' then
    local px, py = read_window_position_windows()
    if px and py then
      x, y = px, py
    end
  end

  local payload = wezterm.json_encode {
    pixel_width = dims.pixel_width,
    pixel_height = dims.pixel_height,
    x = x,
    y = y,
  }
  local file = io.open(window_geometry_cache, 'w')
  if not file then
    return
  end
  file:write(payload)
  file:close()
end

local function schedule_write_window_geometry(window)
  geometry_save_token = geometry_save_token + 1
  local token = geometry_save_token
  wezterm.time.call_after(0.35, function()
    if token ~= geometry_save_token then
      return
    end
    write_window_geometry(window)
  end)
end

wezterm.on('gui-startup', function(cmd)
  local _tab, _pane, window = mux.spawn_window(cmd or {})
  local geo = read_window_geometry()
  if not geo then
    return
  end
  local gui = window:gui_window()
  if geo.x and geo.y then
    gui:set_position(geo.x, geo.y)
  end
  gui:set_inner_size(geo.pixel_width, geo.pixel_height)
end)

wezterm.on('window-resized', function(window, _pane)
  schedule_write_window_geometry(window)
end)

wezterm.on('window-focus-changed', function(window, _pane)
  if not window:is_focused() then
    write_window_geometry(window)
  end
end)

resurrect.state_manager.periodic_save { interval_seconds = 15 * 60, save_workspaces = true }

config.automatically_reload_config = true
config.prefer_to_spawn_tabs = true
config.adjust_window_size_when_changing_font_size = false
config.default_prog = { 'pwsh.exe', '-NoLogo' }
config.bypass_mouse_reporting_modifiers = 'SHIFT'

config.font = wezterm.font_with_fallback {
  'JetBrains Mono',
  'Maple Mono NF CN',
}
config.font_size = 9
config.freetype_load_target = 'Light'
config.freetype_interpreter_version = 40
config.window_frame = {
  font = wezterm.font_with_fallback {
    'JetBrains Mono',
    'Maple Mono NF CN',
  },
  font_size = 9.0,
}
config.command_palette_font_size = 10.0
config.color_scheme = 'Catppuccin Mocha'
config.window_background_opacity = 0.9
config.win32_system_backdrop = 'Acrylic'
config.window_decorations = 'INTEGRATED_BUTTONS|RESIZE'
config.window_close_confirmation = 'AlwaysPrompt'
config.exit_behavior = 'CloseOnCleanExit'

config.scrollback_lines = 10000
config.audible_bell = 'Disabled'
config.visual_bell = {
  fade_in_duration_ms = 75,
  fade_out_duration_ms = 75,
  target = 'CursorColor',
}

config.front_end = 'WebGpu'
config.webgpu_power_preference = 'HighPerformance'
config.max_fps = 120

config.keys = {
  {
    key = 't',
    mods = 'ALT',
    action = act.SpawnTab 'CurrentPaneDomain',
  },
  {
    key = 'w',
    mods = 'ALT',
    action = act.CloseCurrentTab { confirm = true },
  },
  {
    key = "'",
    mods = 'ALT',
    action = act.SplitVertical { domain = 'CurrentPaneDomain' },
  },
  {
    key = '"',
    mods = 'ALT',
    action = act.SplitHorizontal { domain = 'CurrentPaneDomain' },
  },
  {
    key = 'LeftArrow',
    mods = 'ALT',
    action = act.ActivateTabRelative(-1),
  },
  {
    key = 'RightArrow',
    mods = 'ALT',
    action = act.ActivateTabRelative(1),
  },
  {
    key = 'LeftArrow',
    mods = 'ALT|SHIFT',
    action = act.ActivatePaneDirection 'Left',
  },
  {
    key = 'RightArrow',
    mods = 'ALT|SHIFT',
    action = act.ActivatePaneDirection 'Right',
  },
  {
    key = 'UpArrow',
    mods = 'ALT|SHIFT',
    action = act.ActivatePaneDirection 'Up',
  },
  {
    key = 'DownArrow',
    mods = 'ALT|SHIFT',
    action = act.ActivatePaneDirection 'Down',
  },
  {
    key = 'Backspace',
    mods = 'ALT',
    action = act.Multiple {
      act.SendKey { key = 'a', mods = 'CTRL' },
      act.SendKey { key = 'k', mods = 'CTRL' },
    },
  },
  {
    key = 'c',
    mods = 'CTRL|SHIFT',
    action = act.CopyTo 'Clipboard',
  },
  {
    key = 'v',
    mods = 'CTRL|SHIFT',
    action = act.PasteFrom 'Clipboard',
  },
  {
    key = 'v',
    mods = 'ALT',
    action = act.PasteFrom 'Clipboard',
  },
  {
    key = 'Insert',
    mods = 'CTRL',
    action = act.CopyTo 'Clipboard',
  },
  {
    key = 'Insert',
    mods = 'SHIFT',
    action = act.PasteFrom 'Clipboard',
  },
  {
    key = 's',
    mods = 'ALT',
    action = wezterm.action_callback(function(win, pane)
      resurrect.state_manager.save_state(resurrect.workspace_state.get_workspace_state())
    end),
  },
  {
    key = 'r',
    mods = 'ALT',
    action = wezterm.action_callback(function(win, pane)
      resurrect.fuzzy_loader.fuzzy_load(win, pane, function(id, label)
        local type = string.match(id, '^([^/]+)')
        id = string.match(id, '([^/]+)$')
        id = string.match(id, '(.+)%..+$')
        local opts = {
          relative = true,
          restore_text = true,
          on_pane_restore = resurrect.tab_state.default_on_pane_restore,
        }
        if type == 'workspace' then
          local state = resurrect.state_manager.load_state(id, 'workspace')
          resurrect.workspace_state.restore_workspace(state, opts)
        elseif type == 'window' then
          local state = resurrect.state_manager.load_state(id, 'window')
          resurrect.window_state.restore_window(pane:window(), state, opts)
        elseif type == 'tab' then
          local state = resurrect.state_manager.load_state(id, 'tab')
          resurrect.tab_state.restore_tab(pane:tab(), state, opts)
        end
      end)
    end),
  },
  {
    key = 'o',
    mods = 'ALT',
    action = workspace_switcher.switch_workspace(),
  },
  {
    key = 'o',
    mods = 'ALT|SHIFT',
    action = workspace_switcher.switch_to_prev_workspace(),
  },
}

config.mouse_bindings = {
  {
    event = { Up = { streak = 1, button = 'Left' } },
    mods = 'NONE',
    action = act.CompleteSelectionOrOpenLinkAtMouseCursor 'Clipboard',
  },
  {
    event = { Down = { streak = 1, button = 'Right' } },
    mods = 'NONE',
    action = act.PasteFrom 'Clipboard',
  },
}

wezterm.on('format-tab-title', function(tab, tabs, panes, _, hover, max_width)
  local title = tab.tab_title
  if #title == 0 then
    title = tab.active_pane.title
  end
  if tab.active_pane.is_zoomed then
    title = '[Z] ' .. title
  end
  title = wezterm.truncate_right(title, max_width - 4)
  return {
    { Text = ' ' .. (tab.tab_index + 1) .. ': ' .. title .. ' ' },
  }
end)

wezterm.on('update-status', function(window, pane)
  local cwd = ''
  local cwd_uri = pane:get_current_working_dir()
  if cwd_uri then
    cwd = cwd_uri.file_path or ''
    cwd = cwd:match '([^/\\]+)[/\\]?$' or cwd
    if cwd == (wezterm.home_dir:match '([^/\\]+)[/\\]?$') then
      cwd = '~'
    end
  end

  window:set_right_status(wezterm.format {
    { Foreground = { Color = '#89b4fa' } },
    { Text = ' ' .. window:active_workspace() .. ' ' },
    { Foreground = { Color = '#cba6f7' } },
    { Text = ' ' .. cwd .. ' ' },
    { Foreground = { Color = '#a6e3a1' } },
    { Text = ' ' .. wezterm.strftime '%H:%M' .. ' ' },
  })
end)

wezterm.on('smart_workspace_switcher.workspace_switcher.created', function(window, path, label)
  resurrect.workspace_state.restore_workspace(
    resurrect.state_manager.load_state(label, 'workspace'),
    {
      window = window,
      relative = true,
      restore_text = true,
      on_pane_restore = resurrect.tab_state.default_on_pane_restore,
    }
  )
end)

wezterm.on('smart_workspace_switcher.workspace_switcher.selected', function(window, path, label)
  resurrect.state_manager.save_state(resurrect.workspace_state.get_workspace_state())
end)

return config
