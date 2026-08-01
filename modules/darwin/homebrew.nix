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
      cleanup = "check";
      upgrade = false;
      autoUpdate = false;
      extraFlags = [ "--verbose" ];
    };

    casks = [
      "proton-pass"
      "app-cleaner"
      "cleanshot"
      "chatgpt"
      "codex-app"
      "steipete/homebrew-tap/codexbar"
      "coteditor"
      "ghostty"
      "keka"
      "microsoft-office"
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
      "zed"
      "zotero"
    ];
  };

  nix-homebrew = {
    enable = true;
    enableRosetta = false;
    user = darwinHost.username;

    taps = homebrewTaps;

    # With mutable taps disabled, taps can no longer be added imperatively.
    mutableTaps = false;
  };
}
