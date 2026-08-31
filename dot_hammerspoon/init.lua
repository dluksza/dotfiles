-- Hammerspoon: the macOS automation AeroSpace deliberately doesn't do —
-- alerts, audio devices, watchers, arbitrary window geometry.
-- Window tiling itself belongs to AeroSpace (~/.config/aerospace/aerospace.toml),
-- which is installed on the personal host only. This config is shared by every
-- host, so it steps aside where AeroSpace is present.

hs.loadSpoon("ReloadConfiguration")
spoon.ReloadConfiguration:start()

-- Lets `hs -c 'peekSlack()'` reach this config. AeroSpace's cmd-alt-g/s/m
-- bindings call exactly that; without hs.ipc the CLI hangs waiting for a
-- listener.
require("hs.ipc")

-- Preload every extension the hotkeys touch. Hammerspoon lazy-loads on first
-- reference, and that first load can take long enough that a second `hs -c`
-- arriving meanwhile is refused with "hs.ipc: already recursing" — which looks
-- exactly like a dead hotkey.
require("hs.application")
require("hs.window")
require("hs.screen")
require("hs.mouse")
require("hs.timer")
require("hs.alert")

-- Peeks should snap into place, not glide; also avoids reading a frame
-- mid-animation.
hs.window.animationDuration = 0

-- AeroSpace owns cmd-alt where it is installed. Binding the same chord in both
-- would race: whichever process registers the global hotkey first wins, with no
-- error either way. Test for the *installed bundle*, not a running process —
-- login start order between the launchd agent and Hammerspoon isn't guaranteed,
-- so a process check would bind or skip at random.
local aerospaceInstalled = hs.application.pathForBundleID("bobko.aerospace") ~= nil

if not aerospaceInstalled then
	hs.hotkey.bind({ "cmd", "alt" }, "T", function()
		hs.application.launchOrFocus("WezTerm")
	end)

	hs.hotkey.bind({ "cmd", "alt" }, "B", function()
		hs.application.launchOrFocus("Brave Browser")
	end)
end

-- ── Centred "peek" windows ────────────────────────────────────────────────
-- AeroSpace cannot do this part: both its `move` and `resize` commands refuse
-- floating windows (upstream issue #9), and nothing in it sets a window frame.
-- The matching AeroSpace rules mark these three apps `layout floating` so the
-- tiler leaves the geometry alone once we've set it.
--
-- Called from aerospace.toml via `hs -c`, immediately after
-- `summon-workspace C` has pulled the workspace onto the focused monitor.

local PEEK_DELAY = 0.15 -- let AeroSpace finish making the workspace visible

-- Apps are addressed by BUNDLE ID, never by display name. hs.application.open
-- resolves a name against the bundle on disk, and those disagree: Telegram's
-- window reports the name "Telegram" while the app is "Telegram Desktop.app",
-- so open("Telegram") returns nil and the peek silently does nothing.
-- Bundle IDs come from: mdls -name kMDItemCFBundleIdentifier -r /Applications/App.app
--
-- NOTHING here may block. `hs -c` runs synchronously on Hammerspoon's main
-- thread, so the obvious hs.application.open(id, 5, true) — which waits up to
-- five seconds for a first window — freezes the whole config, and a second
-- peek pressed meanwhile dies with "hs.ipc: already recursing". Hence: an
-- async launch plus a polling timer that returns immediately.
local PEEK_POLL = 0.1
local PEEK_MAX_TRIES = 20 -- ~2s for a cold app launch

local function placeWhenReady(bundleID, wFrac, hFrac, attempt)
	local app = hs.application.get(bundleID)
	local win = app and (app:focusedWindow() or app:mainWindow())

	if not win then
		if attempt < PEEK_MAX_TRIES then
			hs.timer.doAfter(PEEK_POLL, function()
				placeWhenReady(bundleID, wFrac, hFrac, attempt + 1)
			end)
		else
			hs.alert.show("peek: no window for " .. bundleID)
		end
		return
	end

	-- The window's own screen, not mainScreen(): centre where the window
	-- actually is, which is the workspace/monitor peek.sh just moved it to.
	local f = (win:screen() or hs.screen.mainScreen()):frame()
	local w, h = f.w * wFrac, f.h * hFrac
	win:setFrame({ x = f.x + (f.w - w) / 2, y = f.y + (f.h - h) / 2, w = w, h = h })
	win:focus()
end

function centerApp(bundleID, wFrac, hFrac)
	hs.application.launchOrFocusByBundleID(bundleID) -- async, returns at once
	placeWhenReady(bundleID, wFrac or 0.6, hFrac or 0.7, 1)
end

-- Per-app wrappers keep the AeroSpace bindings free of nested quoting.
function peekTelegram()
	centerApp("com.tdesktop.Telegram", 0.55, 0.75)
end

function peekSlack()
	centerApp("com.tinyspeck.slackmacgap", 0.70, 0.80)
end

function peekSpotify()
	centerApp("com.spotify.client", 0.65, 0.70)
end

-- ── Pointer ───────────────────────────────────────────────────────────────
-- AeroSpace's move-mouse can only target the FOCUSED monitor, so moving the
-- pointer without moving focus has to happen here.
function pointerToOtherScreen()
	local current = hs.mouse.getCurrentScreen()
	if not current then
		return
	end
	local target = current:next()
	if not target or target:id() == current:id() then
		return -- single screen: nothing to do
	end
	local f = target:fullFrame()
	hs.mouse.absolutePosition({ x = f.x + f.w / 2, y = f.y + f.h / 2 })
end
