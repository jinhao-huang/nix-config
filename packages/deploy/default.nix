{
  lib,
  coreutils,
  git,
  nix,
  writeShellApplication,
}:
writeShellApplication {
  name = "deploy";
  runtimeInputs = [
    coreutils
    git
    nix
  ];
  text = ''
    usage() {
      echo "Usage: nix run .#deploy -- {build|switch} HOST [COMMAND_OPTIONS...]"
      echo "Run in the repository as the regular user; Darwin switch invokes sudo."
    }

    if [[ ''${1-} == --help ]]; then
      usage
      exit 0
    fi
    if [[ $# -lt 2 ]]; then
      usage >&2
      exit 1
    fi

    action=$1
    host=$2
    shift 2
    case "$action" in
      build|switch) ;;
      *) usage >&2; exit 1 ;;
    esac
    if [[ ! $host =~ ^[a-zA-Z0-9][a-zA-Z0-9_-]*$ ]]; then
      echo "Invalid host name: $host" >&2
      exit 1
    fi
    if [[ $EUID -eq 0 ]]; then
      echo "Run deploy as the regular user, without sudo." >&2
      exit 1
    fi

    case "$(uname -s)" in
      Darwin)
        configurations=darwinConfigurations
        build_attribute=system
        cli_attribute=config.system.build.darwin-rebuild
        ;;
      Linux)
        configurations=homeConfigurations
        build_attribute=activationPackage
        cli_attribute=config.programs.home-manager.package
        ;;
      *) echo "Only Darwin and Linux are supported." >&2; exit 1 ;;
    esac

    # The executable lives in the store; locate the writable checkout at runtime.
    if ! repo_root=$(git rev-parse --show-toplevel 2>/dev/null) ||
      [[ ! -f "$repo_root/flake.nix" || ! -f "$repo_root/hosts/empty-local.nix" ]]; then
      echo "Run deploy from the nix-config repository." >&2
      exit 1
    fi
    local_inventory="$repo_root/hosts/inventory.local.nix"
    if [[ ! -e $local_inventory && ! -L $local_inventory ]]; then
      # noclobber also protects a file created after the existence check.
      (
        set -o noclobber
        printf '%s\n' \
          '{' \
          '  # Uncomment to override tracked Pi defaults for this host.' \
          "  # $host.pi = {" \
          '  #   model = { provider = "provider-id"; id = "model-id"; };' \
          '  #   thinkingLevel = "high";' \
          '  # };' \
          '}' > "$local_inventory"
      )
      echo "Created $local_inventory" >&2
    fi
    if [[ ! -f $local_inventory || ! -r $local_inventory ]]; then
      echo "Local inventory must be a readable file: $local_inventory" >&2
      exit 1
    fi

    nix_command=(nix --extra-experimental-features 'nix-command flakes')
    local_flags=(--no-write-lock-file --override-input host-local "path:$local_inventory")
    configuration="$repo_root#$configurations.$host"

    if [[ $action == build ]]; then
      exec "''${nix_command[@]}" build --no-link "$@" "''${local_flags[@]}" \
        "$configuration.$build_attribute"
    fi

    # Resolve the CLI from the selected configuration, including on a fresh machine.
    cli=$("''${nix_command[@]}" build --no-link --print-out-paths \
      "''${local_flags[@]}" "$configuration.$cli_attribute")
    if [[ $configurations == darwinConfigurations ]]; then
      exec sudo -H "$cli/bin/darwin-rebuild" switch "$@" \
        --flake "$repo_root#$host" "''${local_flags[@]}"
    else
      exec "$cli/bin/home-manager" switch "$@" \
        --flake "$repo_root#$host" "''${local_flags[@]}"
    fi
  '';
  meta = {
    description = "Build and activate host environments with local inventory overrides";
    mainProgram = "deploy";
    platforms = lib.platforms.darwin ++ lib.platforms.linux;
  };
}
