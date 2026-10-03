{
  configurationRevision,
  darwinHost,
  ...
}:
{
  imports = [
    ./homebrew.nix
    ./remote-login
    ./tailscale-ingress
  ];

  nix.settings = {
    experimental-features = [
      "nix-command"
      "flakes"
    ];
    trusted-users = [ darwinHost.username ];
  };

  # Enable alternative shell support in nix-darwin.
  # programs.fish.enable = true;

  # Set Git commit hash for darwin-version.
  system.configurationRevision = configurationRevision;

  system.primaryUser = darwinHost.username;

  # Used for backwards compatibility, please read the changelog before changing.
  # $ darwin-rebuild changelog
  system.stateVersion = 6;

  # The platform the configuration will be used on.
  nixpkgs.hostPlatform = darwinHost.system;

  users.users.${darwinHost.username}.home = darwinHost.homeDirectory;

  security.pam.services.sudo_local.touchIdAuth = true;

  system.defaults = {
    NSGlobalDomain.AppleInterfaceStyleSwitchesAutomatically = false;
    NSGlobalDomain.AppleShowAllFiles = true;
    NSGlobalDomain.NSDocumentSaveNewDocumentsToCloud = false;
    # Spring loading: auto-open folders/stacks when hovering while dragging.
    NSGlobalDomain."com.apple.springing.enabled" = true;

    CustomUserPreferences = {
      "com.hezongyidev.Bob".AppleLanguages = [
        "zh-Hans-US"
        "en"
        "en-US"
      ];

      # Disable Spotlight's Cmd-Space (AppleSymbolicHotKeys 64) so Raycast can claim it.
      "com.apple.symbolichotkeys" = {
        AppleSymbolicHotKeys."64" = {
          enabled = false;
        };
      };

      "com.apple.HIToolbox".AppleEnabledInputSources = [
        {
          InputSourceKind = "Keyboard Layout";
          "KeyboardLayout ID" = 252;
          "KeyboardLayout Name" = "ABC";
        }
        {
          "Bundle ID" = "com.apple.inputmethod.SCIM";
          "Input Mode" = "com.apple.inputmethod.SCIM.Shuangpin";
          InputSourceKind = "Input Mode";
        }
        {
          "Bundle ID" = "com.apple.inputmethod.SCIM";
          InputSourceKind = "Keyboard Input Method";
        }
        {
          "Bundle ID" = "com.apple.CharacterPaletteIM";
          InputSourceKind = "Non Keyboard Input Method";
        }
      ];

      "com.apple.inputmethod.CoreChineseEngineFramework".shuangpinLayout = 4;
    };

    finder.AppleShowAllExtensions = true;
    finder.FXPreferredViewStyle = "clmv";
    finder.ShowPathbar = true;
    # "SCcf" scopes searches to the current folder instead of "This Mac".
    finder.FXDefaultSearchScope = "SCcf";
    finder._FXSortFoldersFirst = true;
    finder.FXRemoveOldTrashItems = true;
    finder.NewWindowTarget = "Home";

    trackpad.Clicking = true;
    trackpad.TrackpadRightClick = true;
    trackpad.TrackpadThreeFingerDrag = true;
  };
}
