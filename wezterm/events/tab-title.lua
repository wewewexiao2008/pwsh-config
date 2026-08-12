local wezterm = require 'wezterm'

local M = {}

function M.setup()
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
end

return M
