{
  pkgs,
  self,
  inputs,
  ...
}:
{
  imports = [
    ../proton-pass
  ];

  nixpkgs.config.allowUnfree = true;
  modules.proton-pass.enable = true;

  # List packages installed in system profile. To search by name, run:
  # $ nix-env -qaP | grep wget
  environment.systemPackages = [
  ];

  homebrew = {
    enable = true;
    onActivation = {
      cleanup = "zap";
      upgrade = false;
      autoUpdate = true;
    };

    brews = [
      "mas"
    ];

    casks = [
      "1password"
      "airbuddy"
      "app-cleaner"
      "betterdisplay"
      "cleanshot"
      "steipete/homebrew-tap/codexbar"
      "coteditor"
      "keka"
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

    masApps = {
      "Amphetamine" = 937984704;
      "Bob" = 1630034110;
      "PastePal" = 1503446680;
      "Canary Mail" = 1236045954;
    };
  };

  # Necessary for using flakes on this system.
  nix.settings.experimental-features = "nix-command flakes";

  # Enable alternative shell support in nix-darwin.
  # programs.fish.enable = true;

  # Set Git commit hash for darwin-version.
  system.configurationRevision = self.rev or self.dirtyRev or null;

  system.primaryUser = "jinhaohuang";

  # Used for backwards compatibility, please read the changelog before changing.
  # $ darwin-rebuild changelog
  system.stateVersion = 6;

  # The platform the configuration will be used on.
  nixpkgs.hostPlatform = "aarch64-darwin";

  users.users.jinhaohuang.home = "/Users/jinhaohuang";

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
    user = "jinhaohuang";

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
