local wezterm = require 'wezterm'

local config = wezterm.config_builder()

require('config.plugins').apply_to_config(config)
require('config.general').apply_to_config(config)
require('config.appearance').apply_to_config(config)
require('config.bindings').apply_to_config(config)
require('events.tab-title').setup()
require('events.status').setup()

return config
