function system-update -d "Update system: nix flake, darwin-rebuild, garbage collect, macOS updates"
    echo "━━━ Updating nix flake ━━━"
    nix flake update --flake ~/.config/nix-darwin/ --commit-lock-file
    or return 1

    echo "━━━ Rebuilding system ━━━"
    sudo darwin-rebuild switch --flake ~/.config/nix-darwin/#ziutaPro --refresh --verbose --show-trace
    or return 1

    echo "━━━ Garbage collecting ━━━"
    nix-collect-garbage -d

    echo "━━━ macOS updates ━━━"
    softwareupdate -i -a

    echo "━━━ Syncing dotfiles ━━━"
    chezmoi re-add
    git -C ~/.local/share/chezmoi add dot_config/nix-darwin/flake.lock
    git -C ~/.local/share/chezmoi diff --cached --quiet || git -C ~/.local/share/chezmoi commit -m "Update nix flake lock"
    git -C ~/.local/share/chezmoi push

    echo "━━━ Done ✅ ━━━"
end
