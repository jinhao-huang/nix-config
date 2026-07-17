{
  config,
  lib,
  pkgs,
  ...
}:

let
  cfg = config.modules.mas-apps;
  homebrewCfg = config.homebrew;

  appIds = map (app: app.id) (lib.attrValues cfg.apps);
  bundleIdentifiers = map (app: app.bundleIdentifier) (lib.attrValues cfg.apps);
  masGuard = import ./mas-guard.nix {
    inherit lib pkgs;
    apps = cfg.apps;
    listTimeoutSeconds = cfg.listTimeoutSeconds;
    package = cfg.package;
    searchPaths = cfg.searchPaths;
    user = homebrewCfg.user;
  };
in
{
  options.modules.mas-apps = {
    package = lib.mkOption {
      type = lib.types.package;
      default = pkgs.mas;
      defaultText = lib.literalExpression "pkgs.mas";
      description = "mas package used by the pre-Homebrew metadata guard.";
    };

    apps = lib.mkOption {
      type = lib.types.attrsOf (
        lib.types.submodule {
          options = {
            id = lib.mkOption {
              type = lib.types.ints.positive;
              description = "Mac App Store application identifier.";
            };

            bundleIdentifier = lib.mkOption {
              type = lib.types.str;
              description = "CFBundleIdentifier used to find the installed application independently of Spotlight.";
            };
          };
        }
      );
      default = { };
      description = "Mac App Store applications managed through Homebrew Bundle with Spotlight health checks.";
    };

    searchPaths = lib.mkOption {
      type = lib.types.listOf lib.types.str;
      default = [ "/Applications" ];
      description = ''
        Absolute directories searched for installed application bundles. The
        guard scans applications at the root and one directory below each path.
      '';
    };

    listTimeoutSeconds = lib.mkOption {
      type = lib.types.ints.positive;
      default = 30;
      description = "Maximum time allowed for a mas metadata query before activation fails.";
    };
  };

  config = lib.mkIf (cfg.apps != { }) {
    assertions = [
      {
        assertion = homebrewCfg.enable;
        message = "modules.mas-apps requires homebrew.enable = true.";
      }
      {
        assertion = cfg.searchPaths != [ ] && lib.all (lib.hasPrefix "/") cfg.searchPaths;
        message = "modules.mas-apps.searchPaths must contain at least one absolute path.";
      }
      {
        assertion = lib.all (bundleIdentifier: bundleIdentifier != "") bundleIdentifiers;
        message = "modules.mas-apps bundle identifiers must not be empty.";
      }
      {
        assertion = lib.length appIds == lib.length (lib.unique appIds);
        message = "modules.mas-apps application identifiers must be unique.";
      }
      {
        assertion = lib.length bundleIdentifiers == lib.length (lib.unique bundleIdentifiers);
        message = "modules.mas-apps bundle identifiers must be unique.";
      }
    ];

    # Keep the Homebrew formula declared so cleanup cannot remove the user-facing
    # CLI. The guard uses its Nix package because it runs before Homebrew can
    # install or repair the formula during activation. This also makes the
    # pre-activation dependency part of the system closure.
    homebrew.brews = [ "mas" ];
    homebrew.masApps = lib.mapAttrs (_: app: app.id) cfg.apps;

    # Ordering constraint: this guard must run before the homebrew activation
    # script. nix-darwin executes extraActivation before homebrew; import order
    # does not provide that guarantee.
    system.activationScripts.extraActivation.text = lib.mkAfter ''
      if ! ${masGuard}/bin/mas-metadata-guard; then
        exit 1
      fi
    '';
  };
}
