{
  darwinHost,
  pkgs,
  pkgs-unstable,
  self,
  inputs,
  ...
}:
{
  imports = [
    ./mas-apps.nix
    ../proton-pass
  ];

  nixpkgs.config.allowUnfree = true;
  modules.proton-pass.enable = true;
  modules.mas-apps = {
    # The release-branch package is significantly slower for metadata queries
    # on the current macOS version, so use the current implementation.
    package = pkgs-unstable.mas;

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

  # List packages installed in system profile. To search by name, run:
  # $ nix-env -qaP | grep wget
  environment.systemPackages = [
  ];

  homebrew = {
    enable = true;
    onActivation = {
      cleanup = "check";
      upgrade = true;
      autoUpdate = false;
    };

    casks = [
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

  nix.settings = {
    experimental-features = "nix-command flakes";
    trusted-users = [ darwinHost.username ];
    extra-substituters = [ "https://cache.numtide.com" ];
    extra-trusted-public-keys = [
      "niks3.numtide.com-1:DTx8wZduET09hRmMtKdQDxNNthLQETkc/yaX7M4qK0g="
    ];
  };

  # Enable alternative shell support in nix-darwin.
  # programs.fish.enable = true;

  # Set Git commit hash for darwin-version.
  system.configurationRevision = self.rev or self.dirtyRev or null;

  system.primaryUser = darwinHost.username;

  # Used for backwards compatibility, please read the changelog before changing.
  # $ darwin-rebuild changelog
  system.stateVersion = 6;

  # The platform the configuration will be used on.
  nixpkgs.hostPlatform = darwinHost.system;

  users.users.${darwinHost.username}.home = darwinHost.homeDirectory;

  security.pam.services.sudo_local.touchIdAuth = true;

  system.defaults = {
    finder.AppleShowAllExtensions = true;
    finder.FXPreferredViewStyle = "clmv";
  };

  nix-homebrew = {
    # Install Homebrew under the default prefix
    enable = true;

    # Apple Silicon Only: Also install Homebrew under the default Intel prefix for Rosetta 2
    enableRosetta = false;

    # User owning the Homebrew prefix
    user = darwinHost.username;

    # Optional: Declarative tap management
    taps = {
      "homebrew/homebrew-core" = inputs.homebrew-core;
      "homebrew/homebrew-cask" = inputs.homebrew-cask;
      "steipete/homebrew-tap" = inputs.homebrew-steipete;
    };

    # Optional: Enable fully-declarative tap management
    #
    # With mutableTaps disabled, taps can no longer be added imperatively with `brew tap`.
    mutableTaps = false;
  };
}
