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

  # Daily (non-admin) work account (exact short name from `dscl . -list /Users`).
  # system.primaryUser tracks this, so all per-user macOS defaults (dock,
  # finder, shortcuts, ...) land here even though `sudo darwin-rebuild` runs
  # from the admin account (darlukadmin). Short names are case-sensitive here.
  _module.args.user = "darluk";
  _module.args.uid = 503; # darluk, from `dscl . -list /Users UniqueID`
  # Homebrew owner + the account that runs `brew bundle` during activation.
  # Casks (stats, ...) install to /Applications, writable only by the admin
  # group, so the non-admin darluk cannot install them — run brew as the admin.
  # /opt/homebrew must be owned by it: sudo chown -R darlukadmin /opt/homebrew
  _module.args.adminUser = "darlukadmin";

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

  homebrew.brews = [
    "docker"            # Docker CLI client
    "devcontainer"      # Dev Containers CLI
    "openapi-generator" # OpenAPI client/server codegen
    "yarn"
  ];
  homebrew.casks = [
    "android-platform-tools" # standalone adb / fastboot on PATH
    "claude-code"            # Claude Code CLI
    "docker-desktop"         # Docker Desktop (engine + GUI)
  ];

  # OPTIONAL: give the machine a stable name on every rebuild. Left disabled
  # so it does not fight an MDM-managed hostname. Uncomment if you want to own it.
  # networking.computerName  = "Ziuta Work";
  # networking.hostName      = "ziuta-work";
  # networking.localHostName = "ziuta-work";
}
