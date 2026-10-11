{ pkgs, ... }:
# AeroSpace — i3-like tiling window manager. Replaces the Hammerspoon config,
# which only held the cmd-alt-t / cmd-alt-b launchers (now in aerospace.toml).
#
# Deliberately NOT using nix-darwin's `services.aerospace`: that module always
# passes `--config-path` to a TOML generated from its `settings` option, so the
# config would live in the nix store and every keybinding tweak would need a
# `darwin-rebuild switch`. (The module's `optionalString (cfg.settings != {})`
# guard never fires — the settings submodule's own option defaults make the
# attrset non-empty even when you set nothing.)
#
# Instead: install the package and declare the launchd agent here, with no
# --config-path. AeroSpace then falls back to its own config search, finding
# the chezmoi-managed ~/.config/aerospace/aerospace.toml. That file sets
# auto-reload-config, so edits apply on save — the same loop the
# ReloadConfiguration spoon gave Hammerspoon.
#
# Editing: `chezmoi edit ~/.config/aerospace/aerospace.toml && chezmoi apply`.
# Only a version bump or a change to this file needs a rebuild.
#
# AeroSpace needs macOS Accessibility permission. Grant it on first launch;
# expect a re-prompt after version bumps, since the store path changes.
{
  # Puts the `aerospace` CLI on PATH and links AeroSpace.app into
  # /Applications/Nix Apps.
  environment.systemPackages = [ pkgs.aerospace ];

  # launchd owns startup, so aerospace.toml keeps `start-at-login = false`.
  launchd.user.agents.aerospace = {
    command = "${pkgs.aerospace}/Applications/AeroSpace.app/Contents/MacOS/AeroSpace";
    serviceConfig = {
      KeepAlive = true;
      RunAtLoad = true;
    };
  };
}
