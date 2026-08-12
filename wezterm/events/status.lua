local wezterm = require 'wezterm'

local M = {}

function M.setup()
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
end

return M
