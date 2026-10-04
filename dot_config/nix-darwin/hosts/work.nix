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
  _module.args.user = "darluk";
  _module.args.adminUser = "darlukadmin";
  _module.args.uid = 503;

  # VS Code with the Flutter/Dart stack baked in (declarative, reproducible).
  # Extension versions track nixpkgs; if you need bleeding-edge extensions,
  # swap this for the `vscode` cask + `code --install-extension`.
  environment.systemPackages = with pkgs; [
    docker
    devcontainer
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

  homebrew.brews = [
    "tfenv"
    "awscli"
    "openapi-generator"
  ];

  homebrew.casks = [
    "android-platform-tools" # standalone adb / fastboot on PATH
    "claude-code"
  ];

  # Pin the machine name: every activation re-applies it via `scutil --set`,
  # so any drift is reset to SHIHTZU on the next rebuild.
  networking.computerName  = "SHIHTZU";
  networking.hostName      = "SHIHTZU";
  networking.localHostName = "SHIHTZU";
}
