{
  description = "MacOs Nix Flake";

  inputs = {
    nixpkgs.url = "github:NixOS/nixpkgs/nixpkgs-unstable";
    # Pin direnv to 2.36.0 (last commit before nixpkgs bumped to 2.37.x, which hangs at startup)
    nixpkgs-direnv-pin.url = "github:NixOS/nixpkgs/117b163b7844dca825a3b54fb473336126c55c9b";
    nix-darwin = {
        url = "github:nix-darwin/nix-darwin/master";
        inputs.nixpkgs.follows = "nixpkgs";
      };
    nix-homebrew = {
        url = "github:zhaofengli-wip/nix-homebrew";
        inputs.brew-src.follows = "brew-src";
      };
    brew-src = {
        url = "github:Homebrew/brew";
        flake = false;
      };
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
      nixpkgs.overlays = [
        (final: prev: {
          direnv = (import inputs.nixpkgs-direnv-pin {
            inherit (prev.stdenv.hostPlatform) system;
            config.allowUnfree = true;
          }).direnv;
          # folly 2026.01.19.00 fails to compile against libc++ 21: the removed
          # _LIBCPP_HAS_ASAN macros make UninitializedMemoryHacks.h emit
          # __sanitizer_annotate_contiguous_container with ASan off (undeclared
          # identifier), breaking folly's consumers (fbthrift/wangle/watchman).
          folly = prev.folly.overrideAttrs (old: {
            patches = (old.patches or [ ]) ++ [ ./folly-libcxx21-asan.patch ];
          });
        })
      ];

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
        mas
        # yt-dlp
        maccy
        starship
        # gimp
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
        # (vscode-with-extensions.override {
        #     vscodeExtensions = with vscode-extensions; [
        #       dart-code.dart-code
        #       dart-code.flutter
        #       zhuangtongfa.material-theme
        #       vscodevim.vim
        #       streetsidesoftware.code-spell-checker
        #       elixir-lsp.vscode-elixir-ls
        #     ];
        #   })
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
            "leoafarias/homebrew-fvm" = inputs.homebrew-fvm;
          };
        };

      homebrew = {
          enable = true;
           brews = [
            "fvm"
            "fastlane"
            "cocoapods"
            "pre-commit"
            "openjdk@17"
            "ollama"
            "lima"
          ];
          casks = [
            "1password"
            "brave-browser"
            "stats"
            "hammerspoon"
            "jordanbaird-ice"
            "synology-drive"
            "google-drive"
            "logi-options+"
#            "garmin-express"
            "font-sf-pro"
            "android-studio"
            "google-chrome"
            "gcloud-cli"
            "zed"
            "nordvpn"
            "spotify"
            "telegram-desktop"
            "codex"
            "garmin-express"
          ];
          masApps = {
            # "Toggl Track: Hours & Time Log" = 1291898086;
            # "WireGuard" = 1451685025;
          };
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
          autohide-delay = 0.0;
          autohide-time-modifier = 0.15;
          mru-spaces = false;
          launchanim = false;
          magnification = true;
          expose-animation-duration = 0.1;
          minimize-to-application = true;
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
          ApplePressAndHoldEnabled = false;
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
        spaces.spans-displays = false;
        WindowManager.EnableStandardClickToShowDesktop = false;
        CustomUserPreferences."com.apple.TimeMachine" = {
            AutoBackup = false;
          };
        universalaccess = {
            reduceMotion = true;
            reduceTransparency = true;
          };
        CustomUserPreferences."com.apple.desktopservices" = {
            DSDontWriteNetworkStores = true;
            DSDontWriteUSBStores = true;
          };
        CustomUserPreferences."com.apple.assistant.support" = {
            AssistantEnabled = false;
          };
        CustomUserPreferences."com.apple.Siri" = {
            StatusMenuVisible = false;
          };
        menuExtraClock = {
            ShowDate = 1; # Always
            Show24Hour = true;
            ShowSeconds = true;
          };
        screensaver = {
            askForPassword = true;
            askForPasswordDelay = 0;
          };

      };
      system.activationScripts.postActivation.text = ''
        for cask in zed brave-browser; do
          brew pin "$cask" 2>/dev/null || true
        done

        # Add Stats and Ice as login items (idempotent — skips if already present)
        for app in "Stats" "Ice"; do
          if ! osascript -e "tell application \"System Events\" to get the name of every login item" 2>/dev/null | grep -q "$app"; then
            osascript -e "tell application \"System Events\" to make login item at end with properties {path:\"/Applications/$app.app\", hidden:false}" 2>/dev/null || true
          fi
        done
      '';

      networking.applicationFirewall = {
          enable = true;
          enableStealthMode = true;
          allowSigned = true;
          allowSignedApp = false;
        };

      environment.etc."ssh/sshd_config.d/200-hardening.conf" = {
          text = ''
            PermitRootLogin no
            PasswordAuthentication no
            KbdInteractiveAuthentication no
            MaxAuthTries 3
            MaxSessions 3
            AllowUsers darek
            ClientAliveInterval 300
            ClientAliveCountMax 2
            X11Forwarding no
          '';
        };

      launchd.daemons.limit-maxfiles = {
          command = "/bin/launchctl limit maxfiles 524288 524288";
          serviceConfig.RunAtLoad = true;
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
