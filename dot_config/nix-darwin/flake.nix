{
  description = "MacOs Nix Flake";

  inputs = {
    nixpkgs.url = "github:NixOS/nixpkgs/nixpkgs-unstable";
    # Pin direnv to 2.36.0 (last commit before nixpkgs bumped to 2.37.x, which hangs at startup)
    nixpkgs-direnv-pin.url = "github:NixOS/nixpkgs/117b163b7844dca825a3b54fb473336126c55c9b";
    nix-darwin = {
        url = "github:nix-darwin/nix-darwin/master";
        inputs.nixpkgs.follows = "nixpkgs";
      };
    nix-homebrew = {
        url = "github:zhaofengli-wip/nix-homebrew";
        inputs.brew-src.follows = "brew-src";
      };
    brew-src = {
        url = "github:Homebrew/brew";
        flake = false;
      };
    homebrew-core = {
        url = "github:homebrew/homebrew-core";
        flake = false;
      };
    homebrew-cask = {
        url = "github:homebrew/homebrew-cask";
        flake= false;
      };
    homebrew-fvm = {
      url = "github:leoafarias/homebrew-fvm";
      flake = false;
    };
  };

  outputs = inputs@{ self, nix-darwin, nixpkgs, nix-homebrew, ... }:
  let
    # Each profile is a host file under ./hosts/ that imports the shared
    # ./modules/. The per-machine login account (user + uid) is hardcoded in
    # the host file via `_module.args` — Nix evaluates purely and cannot run
    # `id -u` itself; bootstrap.sh prints the values to fill in for `work`.
    mkSystem = host: nix-darwin.lib.darwinSystem {
      specialArgs = { inherit inputs; };
      modules = [
        nix-homebrew.darwinModules.nix-homebrew
        host
      ];
    };
  in
  {
    # Build with (profile is a selector, independent of hostname):
    # $ darwin-rebuild switch --flake ~/.config/nix-darwin#personal
    # $ darwin-rebuild switch --flake ~/.config/nix-darwin#work
    darwinConfigurations.personal = mkSystem ./hosts/personal.nix;
    darwinConfigurations.work = mkSystem ./hosts/work.nix;
  };
}
