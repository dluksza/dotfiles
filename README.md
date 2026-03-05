# Software Development dotfiles

macOS dotfiles managed with [chezmoi](https://www.chezmoi.io/) + [nix-darwin](https://github.com/LnL7/nix-darwin).

- **chezmoi** manages dotfiles (shell config, app settings)
- **nix-darwin** manages system configuration, packages (including Homebrew casks)

## Fresh Mac Setup

Prerequisites: Remote Login enabled (System Settings → General → Sharing).

```bash
bash <(curl -sL https://raw.githubusercontent.com/dluksza/dotfiles/main/bootstrap.sh)
```
