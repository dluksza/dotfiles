{ pkgs, inputs, user, uid, adminUser, ... }:
# Shared baseline for ALL machines (personal + work).
# `user`/`uid` are the login account; `adminUser` owns AND runs Homebrew:
# nix-darwin runs `brew bundle` as `sudo --user=homebrew.user` (defaults to
# system.primaryUser), and casks install to /Applications which only the admin
# group can write — so both nix-homebrew.user and homebrew.user must be the
# admin account. All three args come per-host via `_module.args` in
# ../hosts/*.nix. On a single-account machine (personal) set adminUser = user.
# Anything in here is identical on every host. Host-specific or
# profile-specific additions live in ./flutter.nix, ./personal.nix
# and the per-host files under ../hosts/.
{
  imports = [ ./monitoring.nix ];

  nix.enable = false;
  # Temp workaround: nix-darwin's HTML manual builder (rev a1fa429, current
  # master) passes `--toc-depth`, which newer nixpkgs-unstable nixos-render-docs
  # removed in favor of `--sidebar-depth`, breaking darwin-manual-html /
  # darwin-help. Disabling the HTML doc keeps manpages. The darwin-uninstaller
  # package embeds its own default darwin-system (doc.enable=true) that also
  # builds the manual, so it must be disabled too. Remove both once nix-darwin
  # PR #1818 lands on master and the lock is updated.
  documentation.doc.enable = false;
  system.tools.darwin-uninstaller.enable = false;
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
    # wezterm is deliberately NOT here: it comes from the Homebrew cask below.
    # The nix build is ad-hoc signed (codesign: flags=0x2(adhoc), no Team ID), so
    # TCC pins its cdhash and every nixpkgs bump made macOS forget the Full Disk
    # Access grant on the terminal. The cask is upstream-signed with a stable
    # identity, so one grant survives updates. Nothing here calls the `wezterm`
    # CLI (only `open -a WezTerm`, the bundle id, and Hammerspoon launchOrFocus),
    # so dropping the package costs nothing.
    zinit
    fzf
    xh
    tree
    aspell
    hunspell
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
    user = adminUser; # owns /opt/homebrew
    autoMigrate = false;
    mutableTaps = true;
    taps = {
      "homebrew/homebrew-core" = inputs.homebrew-core;
      "homebrew/homebrew-cask" = inputs.homebrew-cask;
      "leoafarias/homebrew-fvm" = inputs.homebrew-fvm;
      # Homebrew resolves tap `jundot/omlx` to this directory name; the
      # upstream repo is `omlx`, so a plain `brew tap jundot/omlx` would
      # 404 — the flake input is what makes it resolvable.
      "jundot/homebrew-omlx" = inputs.homebrew-omlx;
      # Resolves `incoai/tap`; splash brew declared in ./personal.nix.
      "incoai/homebrew-tap" = inputs.homebrew-incoai;
    };
  };

  homebrew = {
    enable = true;
    # Run `brew bundle` as the admin account (matches nix-homebrew.user above).
    # Without this it defaults to system.primaryUser (the non-admin login user),
    # which cannot write /opt/homebrew nor install casks to /Applications.
    user = adminUser;
    # Declared so `onActivation.cleanup` does not try to untap them — Homebrew
    # refuses to untap while a tap still owns installed formulae/casks, which
    # otherwise fails the rebuild. leoafarias/fvm is declared in ./flutter.nix
    # next to the fvm brew that needs it.
    taps = [
      "homebrew/core"
      "homebrew/cask"
    ];
    # Formulae present on every machine.
    brews = [
      # watchman was pkgs.watchman until nixpkgs folly 2026.01.19.00 stopped
      # compiling against libc++ 21 (see ../folly-libcxx21-asan.patch), which
      # broke the whole folly -> fizz/wangle/fbthrift/edencommon/mvfst ->
      # watchman chain and with it system-path. homebrew-core ships an
      # arm64 bottle, so nothing is built locally.
      "watchman"
      "pi-coding-agent"
      "zoxide"
      "mise"
    ];
    # Casks present on every machine. Profile-specific casks are added
    # in ./flutter.nix / ./personal.nix / ../hosts/work.nix.
    casks = [
      "1password"
      "brave-browser"
      # "stats"
      "airstats"
      "thaw"
      "hammerspoon"
      "font-sf-pro"
      # Stable code identity => the Full Disk Access grant on the terminal
      # survives updates (see the note in environment.systemPackages above).
      #
      # The @nightly cask is the right one here, not the plain `wezterm` cask:
      #  - same build line as the nix package this replaces (nixpkgs was on
      #    0-unstable-2026-11-20; the plain cask is frozen at 20240203, i.e. a
      #    ~2-year downgrade).
      #  - verified signed: Developer ID Application: Wesley FURLONG
      #    (P4A6FU9KZ3), hardened runtime, timestamped — so TCC keys on
      #    team+bundle-id instead of a cdhash that changed on every rebuild.
      #  - ships the `wezterm` / `wezterm-gui` / `wezterm-mux-server` /
      #    `strip-ansi-escapes` CLI binaries; the plain cask does not.
      # conflicts_with the plain cask, so never declare both.
      "wezterm@nightly"
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

  # neovim (in systemPackages) is the only editor; macOS ships /usr/bin/vim
  # for the `vi`/`vim` commands. programs.vim is intentionally not enabled:
  # it would pull in pkgs.vim-full (GTK build) which is unused.
  environment.variables.EDITOR = "nvim";

  # zsh (from nixpkgs) is the login shell on every host. nix-darwin's
  # programs.zsh.enable already defaults to true — it puts pkgs.zsh in
  # systemPackages and generates /etc/zshenv, /etc/zprofile and /etc/zshrc —
  # so the options below are spelled out explicitly instead of relying on that
  # default, and they decide what the generated /etc/zshrc does and does not do.
  #
  # Interactive configuration lives in ~/.zshrc (chezmoi), not here: aliases
  # and prompt tweaks there cost no rebuild.
  programs.zsh = {
    enable = true;

    # Completion: /etc/zshenv adds the nix profiles' share/zsh/site-functions
    # to $fpath (that is pkgs.nix-zsh-completions: darwin-rebuild, nix, etc.).
    enableCompletion = true;

    # compinit is deliberately left to ~/.zshrc, for ordering only: /etc/zshrc
    # runs before ~/.zshrc, so a compinit here would build the completion table
    # before zinit has put its plugin completions on $fpath. ~/.zshrc calls
    # compinit once, after the plugins. (This used to be justified with a
    # "compdump hangs" note and a `compinit -D` workaround; -D actually forces a
    # full 2811-file $fpath rescan on every shell — 230 ms vs 118 ms — so it is
    # gone.) enableBashCompletion must stay off too: bashcompinit needs compinit
    # to have run first, and /etc/zshrc runs before ~/.zshrc.
    enableGlobalCompInit = false;
    enableBashCompletion = false;

    # Plugins sourced by /etc/zshrc, i.e. before ~/.zshrc. Versions are pinned
    # by the flake and nothing is fetched from the network at shell start.
    enableAutosuggestions = true;
    enableSyntaxHighlighting = true;
    enableFzfCompletion = true; # tab / ** completion via pkgs.fzf
    enableFzfHistory = true;    # Ctrl-R
    enableFzfGit = true;        # Ctrl-G git browser

    histSize = 5000;
    saveSize = 5000;

    # Default is `prompt suse`; starship owns the prompt from ~/.zshrc.
    promptInit = "";
  };

  # pkgs.zinit ships share/zinit/zinit.zsh, but nix-darwin only links /bin and
  # /share/locale by default (plus /share/zsh from programs.zsh above), so the
  # file would stay unreachable in the store. ~/.zshrc sources it from
  # /run/current-system/sw/share/zinit/zinit.zsh.
  environment.pathsToLink = [ "/share/zinit" ];

  # /etc/shells: /bin/zsh is listed by macOS, the nix zsh is not, and chsh /
  # System Settings > Users & Groups refuse a shell that is not listed.
  # types.shellPackage maps pkgs.zsh to /run/current-system/sw/bin/zsh, which
  # survives nixpkgs bumps (a raw store path would not).
  environment.shells = [ pkgs.zsh ];

  users.knownUsers = [ user ];
  users.users.${user} = {
    uid = uid;
    shell = pkgs.zsh;
  };
  nix.settings.trusted-users = [ user ];

  # The platform the configuration will be used on.
  nixpkgs.hostPlatform = "aarch64-darwin";
}
