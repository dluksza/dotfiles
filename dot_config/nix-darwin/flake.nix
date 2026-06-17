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
    # Build a darwin system from a single host module. `inputs` (incl. self)
    # is threaded into every module via specialArgs so modules can reach the
    # flake inputs (direnv pin overlay, homebrew taps, configurationRevision).
    mkSystem = hostModule: nix-darwin.lib.darwinSystem {
      specialArgs = { inherit inputs; };
      modules = [
        nix-homebrew.darwinModules.nix-homebrew
        hostModule
      ];
    };

    personalSystem = mkSystem ./hosts/personal.nix;
  in
  {
    # Select the profile explicitly at build time — the attribute name is a
    # selector, NOT the machine hostname:
    #   personal:  darwin-rebuild switch --flake .#personal   (alias: .#ziutaPro)
    #   work:      darwin-rebuild switch --flake .#work
    darwinConfigurations = {
      personal = personalSystem;
      ziutaPro = personalSystem; # backwards-compatible alias for the personal Mac
      work     = mkSystem ./hosts/work.nix;
    };
  };
}
