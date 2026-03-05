-- Pull in the wezterm API
local wezterm = require("wezterm")

-- This will hold the configuration.
local config = wezterm.config_builder()

config.window_background_opacity = 0.82
config.font_size = 12.5
config.font = wezterm.font("Fira Code", { weight = 450 })

-- config.show_close_tab_button_in_tabs = false
config.show_new_tab_button_in_tab_bar = false
config.window_decorations = "INTEGRATED_BUTTONS|RESIZE"
config.macos_window_background_blur = 10

config.disable_default_key_bindings = true

config.keys = {
	{ key = "Enter", mods = "SHIFT", action = wezterm.action({ SendString = "\x1b\r" }) },

	-- Font size (CMD only, no Ctrl)
	{ key = "-", mods = "CMD", action = wezterm.action.DecreaseFontSize },
	{ key = "=", mods = "CMD", action = wezterm.action.IncreaseFontSize },
	{ key = "0", mods = "CMD", action = wezterm.action.ResetFontSize },

	-- Clipboard
	{ key = "c", mods = "CMD", action = wezterm.action.CopyTo("Clipboard") },
	{ key = "v", mods = "CMD", action = wezterm.action.PasteFrom("Clipboard") },

	-- Tabs
	{ key = "t", mods = "CMD", action = wezterm.action.SpawnTab("CurrentPaneDomain") },
	{ key = "w", mods = "CMD", action = wezterm.action.CloseCurrentTab({ confirm = true }) },
	{ key = "[", mods = "CMD|SHIFT", action = wezterm.action.ActivateTabRelative(-1) },
	{ key = "]", mods = "CMD|SHIFT", action = wezterm.action.ActivateTabRelative(1) },
	{ key = "[", mods = "CMD|OPT", action = wezterm.action.MoveTabRelative(-1) },
	{ key = "]", mods = "CMD|OPT", action = wezterm.action.MoveTabRelative(1) },
	{ key = "1", mods = "CMD", action = wezterm.action.ActivateTab(0) },
	{ key = "2", mods = "CMD", action = wezterm.action.ActivateTab(1) },
	{ key = "3", mods = "CMD", action = wezterm.action.ActivateTab(2) },
	{ key = "4", mods = "CMD", action = wezterm.action.ActivateTab(3) },
	{ key = "5", mods = "CMD", action = wezterm.action.ActivateTab(4) },
	{ key = "6", mods = "CMD", action = wezterm.action.ActivateTab(5) },
	{ key = "7", mods = "CMD", action = wezterm.action.ActivateTab(6) },
	{ key = "8", mods = "CMD", action = wezterm.action.ActivateTab(7) },
	{ key = "9", mods = "CMD", action = wezterm.action.ActivateTab(8) },

	-- Window
	{ key = "n", mods = "CMD", action = wezterm.action.SpawnWindow },
	{ key = "m", mods = "CMD", action = wezterm.action.Hide },
	{ key = "q", mods = "CMD", action = wezterm.action.QuitApplication },
	{ key = "h", mods = "CMD", action = wezterm.action.HideApplication },
	{ key = "f", mods = "CMD", action = wezterm.action.ToggleFullScreen },

	-- Search & debug
	{ key = "f", mods = "CMD|SHIFT", action = wezterm.action.Search({ CaseInSensitiveString = "" }) },
	{ key = "l", mods = "CMD|SHIFT", action = wezterm.action.ShowDebugOverlay },

	-- Pane splitting
	{ key = "d", mods = "CMD", action = wezterm.action.SplitHorizontal({ domain = "CurrentPaneDomain" }) },
	{ key = "d", mods = "CMD|SHIFT", action = wezterm.action.SplitVertical({ domain = "CurrentPaneDomain" }) },
}

return config
