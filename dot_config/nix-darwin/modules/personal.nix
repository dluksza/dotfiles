{ pkgs, lib, ... }:
# Personal-machine-only software. NOT imported on the work host.
{
  environment.systemPackages = with pkgs; [
    obsidian
    slack
    doppler
    devenv
    rustup
    aerospace # tiling WM; agent + config notes below
  ];

  homebrew = {
    # omlx is served by the jundot/omlx tap (source pinned in ../flake.nix,
    # wired up via nix-homebrew.taps in ./common.nix). Declared here so
    # onActivation cleanup = "zap" keeps it instead of failing to untap it.
    #
    # trusted: Homebrew 6.0 turned on HOMEBREW_REQUIRE_TAP_TRUST, which refuses
    # to load formulae from non-official taps ("Refusing to load formula
    # jundot/omlx/omlx from untrusted tap"). The per-brew `trusted: true` that
    # nix-darwin emits by default is ignored for a plain name like "omlx" —
    # brew only maps fully-qualified names to a tap — so the trust has to come
    # from the tap entry.
    taps = [
      {
        name = "jundot/omlx";
        trusted = true;
      }
    ];
    brews = [
      "lima"
      {
        # Local MLX LLM inference server (formula, not a cask).
        #
        # with-custom-kernel builds the native GLM-5.2 / MiniMax M3 /
        # Qwen3.5-3.6 kernels; without it those families silently fall back to
        # much slower generic paths. The README claims this needs --HEAD, but
        # the guard in Formula/omlx.rb only requires the kernel sources to be
        # present, and tag v0.5.3 ships all three csrc trees — so the pinned
        # stable build is enough. Costs a long from-source compile.
        name = "omlx";
        args = [ "with-custom-kernel" ];
      }
    ];
    casks = [
      "synology-drive"
      "google-drive"
      "openlogi"
      "gcloud-cli"
      "zed"
      "nordvpn"
      "spotify"
      "telegram-desktop"
      "codex"
      "garmin-express"
    ];
  };

  # Obsidian pinned to the Dock on the personal machine only.
  # mkAfter forces it to merge *after* common's Brave -> [ Brave, Obsidian ],
  # matching the pre-split Dock order.
  system.defaults.dock.persistent-apps = lib.mkAfter [
    "${pkgs.obsidian}/Applications/Obsidian.app/"
  ];

  # AeroSpace — i3-like tiling window manager, replacing the Hammerspoon config
  # that only held the cmd-alt-t / cmd-alt-b launchers.
  #
  # Deliberately NOT nix-darwin's `services.aerospace`: that module always
  # passes `--config-path` to a TOML generated from its `settings` option, so
  # the config would live in the nix store and every keybinding tweak would
  # need a rebuild. (Its `optionalString (cfg.settings != {})` guard never
  # fires — the settings submodule's own option defaults keep the attrset
  # non-empty even when you set nothing.)
  #
  # With no --config-path, AeroSpace falls back to its own config search and
  # finds the chezmoi-managed ~/.config/aerospace/aerospace.toml, which sets
  # auto-reload-config — so edits apply on save, the loop the
  # ReloadConfiguration spoon used to give Hammerspoon. Only a version bump or
  # a change to this block needs `darwin-rebuild switch`.
  #
  # launchd owns startup, so aerospace.toml keeps `start-at-login = false`.
  # AeroSpace needs macOS Accessibility permission; expect a re-prompt after
  # version bumps, since the store path changes.
  launchd.user.agents.aerospace = {
    command = "${pkgs.aerospace}/Applications/AeroSpace.app/Contents/MacOS/AeroSpace";
    serviceConfig = {
      KeepAlive = true;
      RunAtLoad = true;
    };
  };
}
