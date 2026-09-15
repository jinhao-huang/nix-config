{
  darwinHost,
  homebrewTaps,
  masPackage,
  ...
}:

{
  imports = [
    ./mas-apps.nix
  ];

  modules.mas-apps = {
    # The release-branch package is significantly slower for metadata queries
    # on the current macOS version, so use the current implementation.
    package = masPackage;

    apps = {
      "Amphetamine" = {
        id = 937984704;
        bundleIdentifier = "com.if.Amphetamine";
      };
      "Bob" = {
        id = 1630034110;
        bundleIdentifier = "com.hezongyidev.Bob";
      };
      "Canary Mail" = {
        id = 1236045954;
        bundleIdentifier = "io.canarymail.mac";
      };
      "Immersive Translate" = {
        id = 6447957425;
        bundleIdentifier = "com.immersivetranslate.Immersive-Translate";
      };
      "Keynote" = {
        id = 361285480;
        bundleIdentifier = "com.apple.iWork.Keynote";
      };
      "Numbers" = {
        id = 361304891;
        bundleIdentifier = "com.apple.iWork.Numbers";
      };
      "Pages" = {
        id = 361309726;
        bundleIdentifier = "com.apple.iWork.Pages";
      };
      "PastePal" = {
        id = 1503446680;
        bundleIdentifier = "com.onmyway133.PastePal";
      };
      "Proton Pass for Safari" = {
        id = 6502835663;
        bundleIdentifier = "me.proton.pass.catalyst";
      };
      "TestFlight" = {
        id = 899247664;
        bundleIdentifier = "com.apple.TestFlight";
      };
      "Xcode" = {
        id = 497799835;
        bundleIdentifier = "com.apple.dt.Xcode";
      };
    };
  };

  homebrew = {
    enable = true;
    onActivation = {
      # "check" runs a pre-flight `brew bundle cleanup` with the PREVIOUSLY
      # activated brew, before nix-homebrew swaps in the newly pinned one. If a
      # past activation left a tap snapshot on disk that the old brew cannot
      # parse (e.g. `command_wrapper` needs brew >= 6.0.13), every rebuild
      # deadlocks: the cask DSL error is misreported as "found Homebrew
      # packages not listed in the Brewfile". Unlock by running the current
      # profile's setup script, then rebuild:
      #   sudo "$(grep -o '/nix/store/[a-z0-9]*-setup-homebrew' "$(readlink -f /nix/var/nix/profiles/system)/activate" | head -1)"
      #   sudo darwin-rebuild switch --flake .#laptop
      cleanup = "check";
      upgrade = false;
      autoUpdate = false;
      extraFlags = [ "--verbose" ];
    };

    casks = [
      "adobe-creative-cloud"
      "proton-pass"
      "app-cleaner"
      "cleanshot"
      "chatgpt"
      "steipete/homebrew-tap/codexbar"
      "coteditor"
      "drawio"
      "ghostty"
      "google-chrome"
      "keka"
      "jinhao-huang/homebrew-tap/microsoft-office-slim"
      "obsidian"
      "omnigraffle"
      "orbstack"
      "proton-mail"
      "raycast"
      "rustdesk"
      "surge"
      "tableplus"
      "tower"
      "typora"
      "visual-studio-code"
      "zcode"
      "zed"
      "zotero"
    ];
  };

  nix-homebrew = {
    enable = true;
    enableRosetta = false;
    user = darwinHost.username;

    # Update this input (which re-pins `brew-src`) in the same change as any
    # homebrew-* tap update: newer tap snapshots may use cask DSL that an
    # older pinned brew cannot parse, aborting activation.
    taps = homebrewTaps;

    # With mutable taps disabled, taps can no longer be added imperatively.
    mutableTaps = false;
  };
}
