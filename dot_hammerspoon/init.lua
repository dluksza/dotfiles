hs.loadSpoon("ReloadConfiguration")
spoon.ReloadConfiguration:start()

hs.hotkey.bind({ "cmd", "alt" }, "T", function()
	hs.application.launchOrFocus("WezTerm")
end)

-- hs.hotkey.bind({ "cmd", "alt" }, "E", function()
-- 	hs.application.launchOrFocus("Emacs")
-- end)

hs.hotkey.bind({ "cmd", "alt" }, "B", function()
	hs.application.launchOrFocus("Brave Browser")
end)

-- function swichAudioOutput()
--   local allOutDevides = hs.audiodevice.allOutputDevices()
--   local currentOutDevice = hs.audiodevice.defaultOutputDevice():name()
-- end

id = nil
modal = hs.hotkey.modal.new({ "cmd", "alt" }, "O")
function modal:entered()
	local allOutDevides = hs.audiodevice.allOutputDevices()
	id = hs.alert.show("TEST", hs.alert.defaultStyle, hs.screen.mainScreen(), "infinity")
end

function modal:exited()
	hs.alert.closeSpecific(id)
end

modal:bind("", "0", hs.audiodevice.defaultOutputDevice(), function()
	modal:exit()
end)
-- modal:bind("", "escape", function() modal:exit() end)
modal:bind("", "escape", function()
	modal:exit()
end)
