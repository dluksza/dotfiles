{ ... }:
# Flutter / mobile dev stack shared by both hosts (this is exactly what
# the personal Mac already carries today). Work-only additions such as
# VS Code and the standalone platform-tools live in ../hosts/work.nix.
#
# Xcode itself is installed out-of-band via `mas` in bootstrap.sh
# (App Store), not declared here.
{
  homebrew = {
    # fvm is served by the leoafarias/fvm tap. Declare it so onActivation
    # cleanup keeps it instead of failing to untap it (it owns the fvm brew).
    #
    # trusted: Homebrew 6.0 turns on HOMEBREW_REQUIRE_TAP_TRUST and refuses to
    # load formulae from non-official taps ("Refusing to load formula
    # leoafarias/fvm/fvm from untrusted tap"), which aborts activation. Marking
    # the tap trusted is what lets brew bundle load anything from it at all
    # (same reason as ./personal.nix).
    taps = [
      {
        name = "leoafarias/fvm";
        trusted = true;
      }
    ];
    brews = [
      # Fully qualified on purpose: fvm has since landed in homebrew-core
      # (same upstream 4.3.2), and a plain "fvm" resolves there. The installed
      # formula came from this tap, and brew refuses to hold both:
      #   Error: fvm was installed from the leoafarias/fvm tap but you are
      #   trying to install it from the homebrew/core tap.
      # The tap-qualified name also makes nix-darwin's per-brew `trusted: true`
      # take effect, since only fully-qualified names map to a tap.
      "leoafarias/fvm/fvm" # Flutter version manager
      "fastlane"           # iOS/Android release automation
      "cocoapods"          # iOS dependency manager
      "openjdk@17"         # Android/Gradle toolchain
      "pre-commit"         # repo hooks
    ];
    casks = [
      "android-studio"
      "google-chrome" # Flutter web target / `flutter run -d chrome`
    ];
  };
}
