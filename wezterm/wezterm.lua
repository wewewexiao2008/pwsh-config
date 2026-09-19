local wezterm = require 'wezterm'

local config = wezterm.config_builder()

-- ~/.config/wezterm is a junction. Watch the loaded config dir and its
-- modules so edits in the real repo trigger reload (wezterm#1697).
local dir = wezterm.config_dir
if dir and dir ~= '' then
  wezterm.add_to_config_reload_watch_list(dir)
  wezterm.add_to_config_reload_watch_list(dir .. '/config')
  wezterm.add_to_config_reload_watch_list(dir .. '/events')
  wezterm.add_to_config_reload_watch_list(dir .. '/utils')
end

wezterm.on('window-config-reloaded', function()
  wezterm.log_info 'pwsh-config: config reloaded'
end)

require('config.plugins').apply_to_config(config)
require('config.general').apply_to_config(config)
require('config.appearance').apply_to_config(config)
require('config.bindings').apply_to_config(config)
require('events.tab-title').setup()
require('events.status').setup()

return config
