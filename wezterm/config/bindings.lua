local wezterm = require 'wezterm'
local act = wezterm.action
local plugins = require 'config.plugins'

local resurrect = plugins.resurrect
local workspace_switcher = plugins.workspace_switcher

local M = {}

local function name_is_herdr(name)
  name = (name or ''):lower()
  return name == 'herdr' or name == 'herdr.exe' or name:match('[/\\]herdr%.exe$') ~= nil
end

local function name_is_wezterm(name)
  name = (name or ''):lower()
  return name:find('wezterm', 1, true) ~= nil
end

local function node_is_herdr(node)
  return node and (name_is_herdr(node.name) or name_is_herdr(node.executable))
end

-- Windows reports the newest descendant as the foreground process (often a
-- shell inside a herdr pane). Walk parents and a shallow child tree, but stop
-- at wezterm itself so a herdr pane does not poison sibling wezterm panes.
local function tree_has_herdr(node, child_depth)
  if not node or child_depth < 0 then
    return false
  end
  if node_is_herdr(node) then
    return true
  end
  local children = node.children
  if not children then
    return false
  end
  for _, child in pairs(children) do
    if tree_has_herdr(child, child_depth - 1) then
      return true
    end
  end
  return false
end

local function pane_is_herdr(pane)
  local ok, info = pcall(function()
    return pane:get_foreground_process_info()
  end)
  if ok and info then
    local node = info
    for _ = 1, 12 do
      if not node then
        break
      end
      if name_is_wezterm(node.name) or name_is_wezterm(node.executable) then
        break
      end
      if tree_has_herdr(node, 3) then
        return true
      end
      if not node.ppid or node.ppid == 0 then
        break
      end
      node = wezterm.procinfo.get_info_for_pid(node.ppid)
    end
  end
  local name_ok, name = pcall(function()
    return pane:get_foreground_process_name()
  end)
  return name_ok and name_is_herdr(name)
end

-- WezTerm matches config.keys before the PTY sees the chord. Send it into the
-- pane only when herdr is in this pane's process tree; otherwise keep the
-- native wezterm action.
local function herdr_or(key, mods, fallback)
  return wezterm.action_callback(function(window, pane)
    if pane_is_herdr(pane) then
      window:perform_action(act.SendKey { key = key, mods = mods }, pane)
    else
      window:perform_action(fallback, pane)
    end
  end)
end

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
      action = herdr_or('t', 'ALT', act.SpawnTab 'CurrentPaneDomain'),
    },
    {
      key = 'w',
      mods = 'ALT',
      action = herdr_or('w', 'ALT', act.CloseCurrentPane { confirm = true }),
    },
    {
      key = 'w',
      mods = 'ALT|SHIFT',
      action = act.CloseCurrentTab { confirm = true },
    },
    -- alt+= = vertical (top/bottom). alt+' = horizontal (left/right).
    -- CTRL|SHIFT+arrow: herdr splits; otherwise wezterm directional split.
    {
      key = 'LeftArrow',
      mods = 'CTRL|SHIFT',
      action = herdr_or('LeftArrow', 'CTRL|SHIFT', act.SplitPane { direction = 'Left', size = { Percent = 50 } }),
    },
    {
      key = 'RightArrow',
      mods = 'CTRL|SHIFT',
      action = herdr_or('RightArrow', 'CTRL|SHIFT', act.SplitPane { direction = 'Right', size = { Percent = 50 } }),
    },
    {
      key = 'UpArrow',
      mods = 'CTRL|SHIFT',
      action = herdr_or('UpArrow', 'CTRL|SHIFT', act.SplitPane { direction = 'Up', size = { Percent = 50 } }),
    },
    {
      key = 'DownArrow',
      mods = 'CTRL|SHIFT',
      action = herdr_or('DownArrow', 'CTRL|SHIFT', act.SplitPane { direction = 'Down', size = { Percent = 50 } }),
    },
    {
      key = '=',
      mods = 'ALT',
      action = act.SplitVertical { domain = 'CurrentPaneDomain' },
    },
    {
      key = "'",
      mods = 'ALT',
      action = act.SplitHorizontal { domain = 'CurrentPaneDomain' },
    },
    {
      key = 'LeftArrow',
      mods = 'ALT',
      action = herdr_or('LeftArrow', 'ALT', act.ActivateTabRelative(-1)),
    },
    {
      key = 'RightArrow',
      mods = 'ALT',
      action = herdr_or('RightArrow', 'ALT', act.ActivateTabRelative(1)),
    },
    {
      key = 'LeftArrow',
      mods = 'ALT|SHIFT',
      action = herdr_or('LeftArrow', 'ALT|SHIFT', act.ActivatePaneDirection 'Left'),
    },
    {
      key = 'RightArrow',
      mods = 'ALT|SHIFT',
      action = herdr_or('RightArrow', 'ALT|SHIFT', act.ActivatePaneDirection 'Right'),
    },
    {
      key = 'UpArrow',
      mods = 'ALT|SHIFT',
      action = herdr_or('UpArrow', 'ALT|SHIFT', act.ActivatePaneDirection 'Up'),
    },
    {
      key = 'DownArrow',
      mods = 'ALT|SHIFT',
      action = herdr_or('DownArrow', 'ALT|SHIFT', act.ActivatePaneDirection 'Down'),
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
