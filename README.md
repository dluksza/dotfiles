# Software Development dotfiles

macOS dotfiles managed with [chezmoi](https://www.chezmoi.io/) + [nix-darwin](https://github.com/nix-darwin/nix-darwin).

- **chezmoi** manages dotfiles (shell config, app settings)
- **nix-darwin** manages system configuration, packages (including Homebrew casks)

## Profiles

One repo, two machine profiles. The profile is an explicit selector — it is
**not** tied to the machine's hostname.

| Profile    | For                          | Contents                                                                 |
| ---------- | ---------------------------- | ------------------------------------------------------------------------ |
| `personal` | Personal Mac (`ziutaPro`)    | Everything: full dev stack + personal apps + personal/secret configs.    |
| `work`     | Company laptop (Flutter dev) | Shared base + Flutter stack + VS Code + adb. No personal apps or secrets. |

What `work` adds on top of the shared base: VS Code with Dart/Flutter/Vim/One
Dark Pro extensions and `android-platform-tools` (standalone `adb`).

What `work` deliberately **omits**: personal apps (Obsidian, Spotify, Telegram,
NordVPN, drives, etc.), `rustup`, and the personal/old-employer configs
(`~/.aws`, `~/.saml2aws`, the `ThePathOfMastery` external).

Config is composed from modules under `dot_config/nix-darwin/`:

```
flake.nix            # outputs: personal, ziutaPro (alias of personal), work
modules/common.nix   # shared base: CLI, editors, terminal, browser, fonts,
                     #   1Password, macOS defaults, touchID-sudo, firewall, sshd
modules/flutter.nix  # fvm, fastlane, cocoapods, openjdk@17, android-studio, chrome
modules/personal.nix # personal-only apps (not imported by work)
hosts/personal.nix   # common + flutter + personal
hosts/work.nix       # common + flutter + VS Code + adb
```

## Fresh Mac Setup

Prerequisites: Remote Login enabled (System Settings → General → Sharing).

The bootstrap installs Nix + nix-darwin, applies chezmoi, and installs Xcode.
Pick the profile up front (non-interactive):

```bash
# Company laptop
PROFILE=work bash <(curl -sL https://raw.githubusercontent.com/dluksza/dotfiles/main/bootstrap.sh)

# Personal Mac
PROFILE=personal bash <(curl -sL https://raw.githubusercontent.com/dluksza/dotfiles/main/bootstrap.sh)
```

Omit `PROFILE=` to be prompted (`1) personal` / `2) work`). The script is
re-entrant: every step is idempotent, so if it fails, fix the cause and re-run
from the top. 1Password sign-in and Apple Account sign-in are the manual steps.

## Day-to-day

```bash
rebuild          # darwin-rebuild switch for THIS machine's profile
system-update    # flake update + rebuild + GC + macOS updates + sync dotfiles
chezmoi update   # pull dotfiles and re-apply
```

`rebuild` and `system-update` resolve the active profile automatically.
The equivalent explicit command is:

```bash
darwin-rebuild switch --flake ~/.config/nix-darwin#<personal|work>
```
