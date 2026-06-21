{ pkgs, inputs, user, uid, ... }:
# Shared baseline for ALL machines (personal + work).
# `user` and `uid` are supplied per-host via `_module.args` in ../hosts/*.nix.
# Anything in here is identical on every host. Host-specific or
# profile-specific additions live in ./flutter.nix, ./personal.nix
# and the per-host files under ../hosts/.
{
  nix.enable = false;
  nixpkgs.config.allowUnfree = true;
  nixpkgs.overlays = [
    (final: prev: {
      direnv = (import inputs.nixpkgs-direnv-pin {
        inherit (prev.stdenv.hostPlatform) system;
        config.allowUnfree = true;
      }).direnv;
    })
  ];

  # CLI + editors + terminal shared everywhere.
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
    zinit
    fzf
    xh
    tree
    aspell
    hunspell
    watchman
    mas
    maccy
    starship
    nixd
    python3
    gh
    uv
    bun
    nodejs
  ];

  fonts.packages = with pkgs; [
    fira-code
    fira-code-symbols
    nerd-fonts.fira-code
  ];

  # Homebrew engine + taps. Both profiles use Homebrew; the fvm tap is
  # required by ./flutter.nix (imported on both hosts).
  nix-homebrew = {
    enable = true;
    enableRosetta = true;
    user = user;
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
    # Declared so `onActivation.cleanup` does not try to untap them — Homebrew
    # refuses to untap while a tap still owns installed formulae/casks, which
    # otherwise fails the rebuild. leoafarias/fvm is declared in ./flutter.nix
    # next to the fvm brew that needs it.
    taps = [
      "homebrew/core"
      "homebrew/cask"
    ];
    # Casks present on every machine. Profile-specific casks are added
    # in ./flutter.nix / ./personal.nix / ../hosts/work.nix.
    casks = [
      "1password"
      "brave-browser"
      "stats"
      "hammerspoon"
      "jordanbaird-ice"
      "font-sf-pro"
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
  system.configurationRevision = inputs.self.rev or inputs.self.dirtyRev or null;
  system.keyboard = {
    enableKeyMapping = true;
    nonUS.remapTilde = true;
    remapCapsLockToEscape = true;
  };

  # Used for backwards compatibility, please read the changelog before changing.
  # $ darwin-rebuild changelog
  system.stateVersion = 6;
  security.pam.services.sudo_local.touchIdAuth = true;

  system.primaryUser = user;
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
      # Apps shared on every machine. Personal adds Obsidian in ./personal.nix.
      persistent-apps = [
        "${pkgs.brave}/Applications/Brave Browser.app/"
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
      ShowMountedServersOnDesktop = true;
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
      AppleMeasurementUnits = "Centimeters";
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
      AllowUsers ${user}
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

  users.knownUsers = [ user ];
  users.users.${user} = {
    uid = uid;
    shell = pkgs.fish;
  };
  nix.settings.trusted-users = [ user ];

  # The platform the configuration will be used on.
  nixpkgs.hostPlatform = "aarch64-darwin";
}
