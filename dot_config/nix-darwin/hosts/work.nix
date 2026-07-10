{ pkgs, ... }:
# Company laptop ("work" profile). Senior Flutter Developer setup:
#   common + flutter, plus work-only dev tooling. No personal apps.
#
# Selected explicitly at build time, independent of the machine hostname:
#   darwin-rebuild switch --flake ~/.config/nix-darwin#work
{
  imports = [
    ../modules/common.nix
    ../modules/flutter.nix
  ];

  # Company laptop login account. Set these to THIS machine's values:
  #   user = output of `whoami`   |   uid = output of `id -u`
  # bootstrap.sh prints both and refuses to build while the placeholder remains.
  _module.args.user = "WORK_USERNAME";
  _module.args.uid = 501;

  # VS Code with the Flutter/Dart stack baked in (declarative, reproducible).
  # Extension versions track nixpkgs; if you need bleeding-edge extensions,
  # swap this for the `vscode` cask + `code --install-extension`.
  environment.systemPackages = with pkgs; [
    (vscode-with-extensions.override {
      vscodeExtensions = with vscode-extensions; [
        dart-code.dart-code
        dart-code.flutter
        zhuangtongfa.material-theme          # dark theme (One Dark Pro)
        vscodevim.vim
        streetsidesoftware.code-spell-checker
      ];
    })
  ];

  homebrew.casks = [
    "android-platform-tools" # standalone adb / fastboot on PATH
  ];

  # OPTIONAL: give the machine a stable name on every rebuild. Left disabled
  # so it does not fight an MDM-managed hostname. Uncomment if you want to own it.
  # networking.computerName  = "Ziuta Work";
  # networking.hostName      = "ziuta-work";
  # networking.localHostName = "ziuta-work";
}
