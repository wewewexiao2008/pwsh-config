local wezterm = require 'wezterm'

local M = {}

function M.apply_to_config(config)
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
  config.front_end = 'WebGpu'
  config.webgpu_power_preference = 'HighPerformance'
  if wezterm.gui then
    config.webgpu_preferred_adapter = require('utils.gpu-adapter'):pick_best()
  end
  config.max_fps = 75
end

return M
