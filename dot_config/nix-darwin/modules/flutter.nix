{ ... }:
# Flutter / mobile dev stack shared by both hosts (this is exactly what
# the personal Mac already carries today). Work-only additions such as
# VS Code and the standalone platform-tools live in ../hosts/work.nix.
#
# Xcode itself is installed out-of-band via `mas` in bootstrap.sh
# (App Store), not declared here.
{
  homebrew = {
    brews = [
      "fvm"        # Flutter version manager
      "fastlane"   # iOS/Android release automation
      "cocoapods"  # iOS dependency manager
      "openjdk@17" # Android/Gradle toolchain
      "pre-commit" # repo hooks
    ];
    casks = [
      "android-studio"
      "google-chrome" # Flutter web target / `flutter run -d chrome`
    ];
  };
}
