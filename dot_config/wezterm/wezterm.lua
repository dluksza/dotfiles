-- Pull in the wezterm API
local wezterm = require("wezterm")

-- This will hold the configuration.
local config = wezterm.config_builder()

config.window_background_opacity = 0.82
config.font_size = 12.5
config.font = wezterm.font("Fira Code", { weight = 450 })

-- config.show_close_tab_button_in_tabs = false
config.show_new_tab_button_in_tab_bar = false

return config
