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

  # Inbound SSH: key accepted by sshd for this account (1Password "DefaultSshKey").
  # Rendered to /etc/ssh/nix_authorized_keys.d/darek via AuthorizedKeysCommand.
  users.users.darek.openssh.authorizedKeys.keys = [
    "ssh-ed25519 AAAAC3NzaC1lZDI1NTE5AAAAINa6Qjp40O531UAnvfZtmgOHJAfX7EHMxqdJT99Ef5i4 DefaultSshKey"
  ];
}
