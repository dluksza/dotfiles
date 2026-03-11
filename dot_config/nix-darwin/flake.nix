{
  description = "MacOs Nix Flake";

  inputs = {
    nixpkgs.url = "github:NixOS/nixpkgs/nixpkgs-unstable";
    nix-darwin = {
        url = "github:nix-darwin/nix-darwin/master";
        inputs.nixpkgs.follows = "nixpkgs";
      };
    nix-homebrew.url = "github:zhaofengli-wip/nix-homebrew";
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
    configuration = { pkgs, ... }: {
      nix.enable = false;
      nixpkgs.config.allowUnfree = true;

      # List packages installed in system profile. To search by name, run:
      # $ nix-env -qaP | grep wget
      environment.systemPackages = with pkgs; [
        chezmoi
        uutils-coreutils-noprefix
        ripgrep
        fish
        age
        git
        git-lfs
        wget
        bat
        fd
        yq
        jaq
        direnv
        neovim
        lua
        nil
        tree-sitter
        wezterm
        obsidian
        zinit
        fzf
        xh
        tree
        aspell
        hunspell
        watchman
        _1password-cli
        spotify
        ncspot
        # yt-dlp
        maccy
        starship
        # gimp
        telegram-desktop
        slack
        doppler
        devenv
        nixd
        # cargo
        python3
        rustup
        gh
        uv
        bun
        nodejs
        (vscode-with-extensions.override {
            vscodeExtensions = with vscode-extensions; [
              dart-code.dart-code
              dart-code.flutter
              zhuangtongfa.material-theme
              vscodevim.vim
              streetsidesoftware.code-spell-checker
              elixir-lsp.vscode-elixir-ls
            ];
          })
      ];

      fonts.packages = with pkgs; [
        fira-code
        fira-code-symbols
        nerd-fonts.fira-code
      ];

      nix-homebrew = {
          enable = true;
          enableRosetta = true;
          user = "darek";
          autoMigrate = false;
          mutableTaps = true;
          taps = {
            "homebrew/homebrew-core" = inputs.homebrew-core;
            "homebrew/homebrew-cask" = inputs.homebrew-cask;
            "homebrew/cask" = inputs.homebrew-cask;
            "leoafarias/homebrew-fvm" = inputs.homebrew-fvm;
          };
        };

      homebrew = {
          enable = true;
          taps = [
            "homebrew/cask"
            "leoafarias/homebrew-fvm"
          ];
           brews = [
            "fvm"
            "fastlane"
            "cocoapods"
            "pre-commit"
          ];
          casks = [
            "lulu"
            "1password"
            "stats"
            "hammerspoon"
            "jordanbaird-ice"
            "synology-drive"
            "google-drive"
            "logi-options+"
            "garmin-express"
            "font-sf-pro"
            "android-studio"
            "proxyman"
            "google-chrome"
            "gcloud-cli"
          ];
          onActivation = {
            cleanup = "zap";
            autoUpdate = true;
            upgrade = true;
          };
        };

      # Necessary for using flakes on this system.
      nix.settings.experimental-features = "nix-command flakes";

      # Set Git commit hash for darwin-version.
      system.configurationRevision = self.rev or self.dirtyRev or null;
      system.keyboard = {
        enableKeyMapping = true;
        nonUS.remapTilde = true;
        remapCapsLockToEscape = true;
      };

      # Used for backwards compatibility, please read the changelog before changing.
      # $ darwin-rebuild changelog
      system.stateVersion = 6;
      security.pam.services.sudo_local.touchIdAuth = true;

      system.primaryUser = "darek";
      system.defaults = {
        dock = {
          largesize = 64;
          autohide = true;
          mru-spaces = false;
          launchanim = false;
          magnification = true;
          orientation = "right";
          show-recents = false;
          tilesize = 28;
          persistent-apps = [
            "${pkgs.brave}/Applications/Brave Browser.app/"
            "${pkgs.obsidian}/Applications/Obsidian.app/"
          ];
          wvous-bl-corner = 1; # Disabled
          wvous-br-corner = 1; # Disabled
          wvous-tr-corner = 1; # Disabled
          wvous-tl-corner = 1; # Disabled
        };
        finder = {
          DisableAllAnimations = true;
          FXPreferredViewStyle = "clmv";
          AppleShowAllExtensions = true;
          NewWindowTarget = "Home";
          ShowMountedServersOnDesktop= true;
          ShowPathbar = true;
          ShowStatusBar = true;
          _FXSortFoldersFirst = true;
          _FXSortFoldersFirstOnDesktop = true;
        };
        loginwindow = {
          GuestEnabled = false;
          LoginwindowText = "Ziuta Pro";
        };
        NSGlobalDomain = {
          AppleMetricUnits = 1;
          AppleKeyboardUIMode = 3;
          AppleScrollerPagingBehavior = true;
          AppleShowScrollBars = "WhenScrolling";
          AppleMeasurementUnits= "Centimeters";
          AppleICUForce24HourTime = true;
          AppleInterfaceStyle = "Dark";
          KeyRepeat = 2;
          InitialKeyRepeat = 15;
          NSAutomaticCapitalizationEnabled = false;
          NSAutomaticDashSubstitutionEnabled = false;
          NSAutomaticInlinePredictionEnabled = false;
          NSAutomaticPeriodSubstitutionEnabled = false;
          NSAutomaticQuoteSubstitutionEnabled = false;
          NSAutomaticSpellingCorrectionEnabled = false;
          NSAutomaticWindowAnimationsEnabled = false;
          NSWindowResizeTime = 0.001;
          "com.apple.keyboard.fnState" = true;
          "com.apple.trackpad.scaling" = 2.5;
          "com.apple.springing.delay" = 0.0;
          "com.apple.springing.enabled" = true;
        };
        controlcenter = {
            AirDrop = false;
            BatteryShowPercentage = true;
          };
        menuExtraClock = {
            ShowDate = 1; # Always
            Show24Hour = true;
            ShowSeconds = true;
          };
      };

      programs.direnv = {
          enable = true;
        };

      programs._1password = {
          enable = true;
        };

      programs.vim = {
          enable = true;
        };

      programs.fish = {
          enable = true;
        };

      users.knownUsers = [ "darek" ];
      users.users.darek = {
          uid = 501;
          shell = pkgs.fish;
        };
      nix.settings.trusted-users = [ "darek" ];

      # The platform the configuration will be used on.
      nixpkgs.hostPlatform = "aarch64-darwin";
    };
  in
  {
    # Build darwin flake using:
    # $ darwin-rebuild build --flake .#ziutaPro
    darwinConfigurations."ziutaPro" = nix-darwin.lib.darwinSystem {
      modules = [
        nix-homebrew.darwinModules.nix-homebrew
        configuration
      ];
    };
  };
}
