{
  config,
  lib,
  pkgs,
  ...
}:

let
  cfg = config.modules.mas-apps;
  homebrewCfg = config.homebrew;
  masBin = "${cfg.package}/bin/mas";
  timeoutBin = "${pkgs.coreutils}/bin/timeout";

  appIds = map (app: app.id) (lib.attrValues cfg.apps);
  bundleIdentifiers = map (app: app.bundleIdentifier) (lib.attrValues cfg.apps);

  searchPathArguments = lib.concatMapStringsSep " " lib.escapeShellArg cfg.searchPaths;

  receiptChecks = lib.concatStringsSep "\n" (
    lib.mapAttrsToList (_: app: ''
      mas_receipt_${toString app.id}=0
      if has_mas_receipt ${lib.escapeShellArg app.bundleIdentifier}; then
        mas_receipt_${toString app.id}=1
        (( mas_receipt_count += 1 ))
      fi
    '') cfg.apps
  );

  # mas list right-aligns numeric IDs, so the generated checks must accept
  # leading whitespace before each configured identifier. Application IDs are
  # also used in shell variable names and must therefore remain positive
  # integers, as enforced by the option type below.
  appChecks = lib.concatStringsSep "\n" (
    lib.mapAttrsToList (name: app: ''
      if (( mas_receipt_${toString app.id} )) \
        && ! printf '%s\n' "$mas_list" \
          | grep -Eq '^[[:space:]]*${toString app.id}[[:space:]]'; then
        printf >&2 '%s\n' ${lib.escapeShellArg "error: ${name} has an App Store receipt, but mas cannot detect it."}
        echo >&2 "Spotlight indexing may be unhealthy. Reboot or repair Spotlight before retrying."
        mas_guard_failed=1
      fi
    '') cfg.apps
  );
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
      echo >&2 "Checking Mac App Store metadata..."

      mas_search_paths=( ${searchPathArguments} )

      # Locate applications by bundle identifier instead of assuming their
      # display names match their bundle directory names. Search depth is
      # intentionally bounded to avoid descending into nested helper apps.
      has_mas_receipt() {
        local expected_bundle_identifier="$1"
        local search_path
        local app_path
        local info_plist
        local actual_bundle_identifier

        for search_path in "''${mas_search_paths[@]}"; do
          [[ -d "$search_path" ]] || continue

          for app_path in "$search_path"/*.app "$search_path"/*/*.app; do
            [[ -d "$app_path" ]] || continue

            info_plist="$app_path/Contents/Info.plist"
            [[ -f "$info_plist" ]] || continue

            actual_bundle_identifier="$(
              /usr/bin/plutil \
                -extract CFBundleIdentifier \
                raw \
                -o - \
                "$info_plist" 2>/dev/null || true
            )"

            if [[ "$actual_bundle_identifier" == "$expected_bundle_identifier" ]] \
              && [[ -f "$app_path/Contents/_MASReceipt/receipt" ]]; then
              return 0
            fi
          done
        done

        return 1
      }

      mas_list=""
      mas_receipt_count=0
      mas_guard_failed=0

      # A fresh installation has no receipts to protect and should proceed
      # directly to Homebrew. When at least one receipt exists, a failed or
      # stalled metadata query is unsafe because Brew Bundle could interpret
      # the empty result as an instruction to reinstall existing applications.
      ${receiptChecks}

      if (( mas_receipt_count > 0 )); then
        if ! mas_list="$(
          sudo \
            --user=${lib.escapeShellArg homebrewCfg.user} \
            --set-home \
            ${lib.escapeShellArg timeoutBin} \
            --signal=TERM \
            ${toString cfg.listTimeoutSeconds}s \
            ${lib.escapeShellArg masBin} list 2>/dev/null
        )"; then
          echo >&2 "error: mas list failed or timed out while installed App Store receipts exist."
          echo >&2 "Aborting activation before Homebrew can make installation decisions."
          exit 1
        fi
      fi

      # A receipt proves that an application is installed without relying on
      # Spotlight. If mas cannot report its ID, Brew Bundle must not use that
      # metadata view to make installation decisions.
      ${appChecks}

      if (( mas_guard_failed )); then
        echo >&2 "Aborting activation to prevent redundant Mac App Store installations."
        exit 1
      fi
    '';
  };
}
