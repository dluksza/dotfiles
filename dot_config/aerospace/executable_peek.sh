#!/usr/bin/env bash
# Bring one app to the CURRENT workspace, focused, for a quick interaction —
# without switching workspace or dragging a whole workspace along.
#
# Why a script and not a binding: AeroSpace's TOML can't name "the workspace I
# am on right now", and `move-node-to-workspace` needs an explicit target. So
# we ask the running server for the focused workspace and move the window here.
# The window is marked `layout floating` by an on-window-detected rule, so it
# lands on top of the tiling layout instead of rearranging it.
#
# Centring is Hammerspoon's job: AeroSpace's move/resize both refuse floating
# windows (upstream issue #9).
#
# usage: peek.sh <app-bundle-id> <hammerspoon-function-name>
set -u

AEROSPACE=/run/current-system/sw/bin/aerospace
HS=/opt/homebrew/bin/hs

bundle_id=${1:?usage: peek.sh <bundle-id> <hs-function>}
peek_fn=${2:?usage: peek.sh <bundle-id> <hs-function>}

ws=$("$AEROSPACE" list-workspaces --focused)

# Match on bundle id, never on app name: the window's reported name and the
# bundle on disk can differ (Telegram vs Telegram Desktop.app).
wid=$("$AEROSPACE" list-windows --all --format '%{window-id} %{app-bundle-id}' |
	awk -v b="$bundle_id" '$2 == b { print $1; exit }')

if [ -n "$wid" ]; then
	"$AEROSPACE" move-node-to-workspace --window-id "$wid" "$ws"
	"$AEROSPACE" focus --window-id "$wid"
fi

# Not running yet: the Hammerspoon side launches it, and the new window is
# detected on the focused workspace anyway.
"$HS" -c "${peek_fn}()"
