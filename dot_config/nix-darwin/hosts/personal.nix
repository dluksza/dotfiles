{ ... }:
# Personal Mac ("ziutaPro"). Equivalent to the pre-split single config:
#   common + flutter (the dev stack already on this machine) + personal.
{
  imports = [
    ../modules/common.nix
    ../modules/flutter.nix
    ../modules/personal.nix
  ];

  # This machine's login account. uid 501 is the standard macOS first-user uid.
  # Single admin account, so it also owns Homebrew (adminUser = user).
  _module.args.user = "darek";
  _module.args.uid = 501;
  _module.args.adminUser = "darek";
}
