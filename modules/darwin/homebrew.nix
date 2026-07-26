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
      "1Password for Safari" = {
        id = 1569813296;
        bundleIdentifier = "com.1password.safari";
      };
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
        id = 409183694;
        bundleIdentifier = "com.apple.iWork.Keynote";
      };
      "Numbers" = {
        id = 409203825;
        bundleIdentifier = "com.apple.iWork.Numbers";
      };
      "Pages" = {
        id = 409201541;
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
    };

    casks = [
      "proton-pass"
      "1password"
      "airbuddy"
      "app-cleaner"
      "betterdisplay"
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
      "tableplus"
      "tower"
      "typora"
      "visual-studio-code"
      "warp"
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
