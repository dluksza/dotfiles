{ ... }:
# Personal Mac ("ziutaPro"). Equivalent to the pre-split single config:
#   common + flutter (the dev stack already on this machine) + personal.
{
  imports = [
    ../modules/common.nix
    ../modules/flutter.nix
    ../modules/personal.nix
  ];
}
