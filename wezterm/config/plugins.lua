local wezterm = require 'wezterm'

local M = {}

M.resurrect = wezterm.plugin.require 'https://github.com/YedPool/resurrect.wezterm'
M.workspace_switcher = wezterm.plugin.require 'https://github.com/MLFlexer/smart_workspace_switcher.wezterm'

function M.apply_to_config(_config)
  M.resurrect.state_manager.periodic_save {
    interval_seconds = 15 * 60,
    save_workspaces = true,
  }

  wezterm.on('smart_workspace_switcher.workspace_switcher.created', function(window, path, label)
    M.resurrect.workspace_state.restore_workspace(
      M.resurrect.state_manager.load_state(label, 'workspace'),
      {
        window = window,
        relative = true,
        restore_text = true,
        on_pane_restore = M.resurrect.tab_state.default_on_pane_restore,
      }
    )
  end)

  wezterm.on('smart_workspace_switcher.workspace_switcher.selected', function(window, path, label)
    M.resurrect.state_manager.save_state(M.resurrect.workspace_state.get_workspace_state())
  end)
end

return M
