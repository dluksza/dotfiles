{ pkgs, lib, ... }:
# Personal-machine-only software. NOT imported on the work host.
{
  environment.systemPackages = with pkgs; [
    obsidian
    slack
    doppler
    devenv
    rustup
  ];

  homebrew = {
    brews = [
      "ollama"
      "lima"
    ];
    casks = [
      "synology-drive"
      "google-drive"
      "logi-options+"
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
}
