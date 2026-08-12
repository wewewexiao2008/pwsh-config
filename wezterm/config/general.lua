local M = {}

function M.apply_to_config(config)
  config.automatically_reload_config = true
  config.prefer_to_spawn_tabs = true
  config.adjust_window_size_when_changing_font_size = false
  config.default_prog = { 'pwsh.exe', '-NoLogo' }
  config.bypass_mouse_reporting_modifiers = 'SHIFT'
  config.window_close_confirmation = 'AlwaysPrompt'
  config.exit_behavior = 'CloseOnCleanExit'
  config.scrollback_lines = 20000
  config.audible_bell = 'Disabled'
  config.visual_bell = {
    fade_in_duration_ms = 75,
    fade_out_duration_ms = 75,
    target = 'CursorColor',
  }
end

return M
