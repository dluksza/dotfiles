{ ... }:
# AeroSpace — i3-like tiling window manager. Replaces the Hammerspoon config,
# which only held the cmd-alt-t / cmd-alt-b launchers (ported below).
#
# nix-darwin runs AeroSpace as a launchd user agent started from the nix store
# and passes `--config-path` pointing at a TOML generated from `settings`.
# Consequences:
#   - ~/.aerospace.toml is IGNORED. Edit this file, then `darwin-rebuild switch`
#     (activation reloads the agent). `aerospace reload-config` re-reads the
#     same generated store file, so it only helps after a rebuild.
#   - `start-at-login` and `after-login-command` must stay unset: launchd owns
#     startup and the module asserts on both.
#   - AeroSpace needs macOS Accessibility permission. Grant it on first launch;
#     expect a re-prompt after version bumps, since the binary path changes.
#
# Workspaces are emulated, not native macOS Spaces: windows of inactive
# workspaces are parked off-screen, so Mission Control and cmd-tab do not
# reflect them.
{
  services.aerospace = {
    enable = true;

    settings = {
      config-version = 2;

      # Normalization keeps the window tree flat and sanely oriented.
      enable-normalization-flatten-containers = true;
      enable-normalization-opposite-orientation-for-nested-containers = true;

      default-root-container-layout = "tiles";
      # Wide monitor -> horizontal split, tall monitor -> vertical.
      default-root-container-orientation = "auto";
      accordion-padding = 30;

      # Mouse jumps to the newly focused monitor, so the pointer never lags
      # behind keyboard focus on a multi-monitor setup.
      on-focused-monitor-changed = [ "move-mouse monitor-lazy-center" ];

      # false = leave macOS cmd-h "Hide application" behavior alone.
      automatically-unhide-macos-hidden-apps = false;

      key-mapping.preset = "qwerty";

      gaps = {
        inner.horizontal = 8;
        inner.vertical = 8;
        outer.left = 8;
        outer.bottom = 8;
        outer.top = 8;
        outer.right = 8;
      };

      mode.main.binding = {
        # --- Layout -------------------------------------------------------
        alt-slash = "layout tiles horizontal vertical";
        alt-comma = "layout accordion horizontal vertical";
        alt-f = "fullscreen";
        alt-shift-space = "layout floating tiling";

        # --- Focus / move -------------------------------------------------
        alt-h = "focus left";
        alt-j = "focus down";
        alt-k = "focus up";
        alt-l = "focus right";

        alt-shift-h = "move left";
        alt-shift-j = "move down";
        alt-shift-k = "move up";
        alt-shift-l = "move right";

        # --- Quick resize without entering resize mode ---------------------
        alt-minus = "resize smart -50";
        alt-equal = "resize smart +50";

        # --- Workspaces ---------------------------------------------------
        alt-1 = "workspace 1";
        alt-2 = "workspace 2";
        alt-3 = "workspace 3";
        alt-4 = "workspace 4";
        alt-5 = "workspace 5";
        alt-6 = "workspace 6";
        alt-7 = "workspace 7";
        alt-8 = "workspace 8";
        alt-9 = "workspace 9";

        alt-shift-1 = "move-node-to-workspace 1";
        alt-shift-2 = "move-node-to-workspace 2";
        alt-shift-3 = "move-node-to-workspace 3";
        alt-shift-4 = "move-node-to-workspace 4";
        alt-shift-5 = "move-node-to-workspace 5";
        alt-shift-6 = "move-node-to-workspace 6";
        alt-shift-7 = "move-node-to-workspace 7";
        alt-shift-8 = "move-node-to-workspace 8";
        alt-shift-9 = "move-node-to-workspace 9";

        alt-tab = "workspace-back-and-forth";
        alt-shift-tab = "move-workspace-to-monitor --wrap-around next";

        # --- Modes --------------------------------------------------------
        alt-r = "mode resize";
        alt-shift-semicolon = "mode service";

        # --- App launchers (ported from .hammerspoon/init.lua) -------------
        # `open -a` matches hs.application.launchOrFocus: it activates a
        # running app rather than starting a second copy. Untested edge case:
        # the app's window sitting on an INACTIVE workspace — AeroSpace does
        # not document whether it follows. If that misbehaves, swap in:
        #   exec-and-forget wid=$(aerospace list-windows --all --format '%{window-id} %{app-bundle-id}' | awk '$2=="com.github.wez.wezterm"{print $1; exit}'); if [ -n "$wid" ]; then aerospace focus --window-id "$wid"; else open -a WezTerm; fi
        cmd-alt-t = "exec-and-forget open -a WezTerm";
        cmd-alt-b = "exec-and-forget open -a 'Brave Browser'";
      };

      # i3-style resize mode: alt-r in, hjkl to size, esc/enter out.
      mode.resize.binding = {
        h = "resize width -50";
        j = "resize height +50";
        k = "resize height -50";
        l = "resize width +50";
        b = [ "balance-sizes" "mode main" ];
        esc = "mode main";
        enter = "mode main";
      };

      # Service mode: infrequent operations kept off the main keymap.
      mode.service.binding = {
        esc = [ "reload-config" "mode main" ];
        r = [ "flatten-workspace-tree" "mode main" ]; # reset layout
        f = [ "layout floating tiling" "mode main" ];
        backspace = [ "close-all-windows-but-current" "mode main" ];

        alt-shift-h = [ "join-with left" "mode main" ];
        alt-shift-j = [ "join-with down" "mode main" ];
        alt-shift-k = [ "join-with up" "mode main" ];
        alt-shift-l = [ "join-with right" "mode main" ];
      };
    };
  };
}
