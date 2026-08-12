local wezterm = require 'wezterm'
local act = wezterm.action
local plugins = require 'config.plugins'

local resurrect = plugins.resurrect
local workspace_switcher = plugins.workspace_switcher

local M = {}

function M.apply_to_config(config)
  config.keys = {
    {
      key = 'F2',
      mods = 'NONE',
      action = act.ActivateCommandPalette,
    },
    {
      key = 'F3',
      mods = 'NONE',
      action = act.ShowLauncher,
    },
    {
      key = 'u',
      mods = 'ALT|CTRL',
      action = act.QuickSelectArgs {
        label = 'open url',
        patterns = {
          '\\((https?://\\S+)\\)',
          '\\[(https?://\\S+)\\]',
          '\\{(https?://\\S+)\\}',
          '<(https?://\\S+)>',
          '\\bhttps?://\\S+[)/a-zA-Z0-9-]+',
        },
        action = wezterm.action_callback(function(window, pane)
          local url = window:get_selection_text_for_pane(pane)
          wezterm.open_with(url)
        end),
      },
    },
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
    -- SplitVertical = top/bottom. SplitHorizontal = left/right.
    -- '"' is Shift+' on US keyboards, so horizontal split needs ALT|SHIFT.
    {
      key = "'",
      mods = 'ALT',
      action = act.SplitVertical { domain = 'CurrentPaneDomain' },
    },
    {
      key = "'",
      mods = 'ALT|SHIFT',
      action = act.SplitHorizontal { domain = 'CurrentPaneDomain' },
    },
    -- Directional splits: new pane opens toward the arrow.
    {
      key = 'LeftArrow',
      mods = 'CTRL|SHIFT',
      action = act.SplitPane { direction = 'Left', size = { Percent = 50 } },
    },
    {
      key = 'RightArrow',
      mods = 'CTRL|SHIFT',
      action = act.SplitPane { direction = 'Right', size = { Percent = 50 } },
    },
    {
      key = 'UpArrow',
      mods = 'CTRL|SHIFT',
      action = act.SplitPane { direction = 'Up', size = { Percent = 50 } },
    },
    {
      key = 'DownArrow',
      mods = 'CTRL|SHIFT',
      action = act.SplitPane { direction = 'Down', size = { Percent = 50 } },
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
      mods = 'CTRL',
      action = act.OpenLinkAtMouseCursor,
    },
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
end

return M
