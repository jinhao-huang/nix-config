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
    deployment_dir=$(mktemp -d -t nix-config-deploy.XXXXXXXXXX)
    trap 'rm -rf -- "$deployment_dir"' EXIT
    command_pid=
    stop_command() {
      trap "" INT TERM
      if [[ -n $command_pid ]]; then
        kill -TERM "$command_pid" 2>/dev/null || true
        wait "$command_pid" || true
      fi
      exit "$1"
    }
    trap 'stop_command 130' INT
    trap 'stop_command 143' TERM

    run_command() {
      local status=0
      # Keep terminal input available and let wait respond to cancellation.
      env --default-signal=INT,TERM "$@" <&0 &
      command_pid=$!
      wait "$command_pid" || status=$?
      command_pid=
      return "$status"
    }

    # Preserve the checkout's cache settings in the deployment flake.
    run_command "''${nix_command[@]}" eval --file "$repo_root/flake.nix" nixConfig \
      > "$deployment_dir/nix-config.nix"
    nix_config=$(< "$deployment_dir/nix-config.nix")

    # Escape the checkout URL as a Nix string in the temporary wrapper flake.
    source_url="git+file://$repo_root"
    source_url=''${source_url//\\/\\\\}
    source_url=''${source_url//\"/\\\"}
    source_url=''${source_url//\$\{/\\\$\{}
    # Keep the original input names so passthrough overrides retain their meaning.
    run_command "''${nix_command[@]}" eval --file "$repo_root/flake.nix" inputs \
      --apply "inputs: inputs // {
        configuration = {
          url = \"$source_url\";
          inputs = builtins.mapAttrs (name: _: { follows = name; }) inputs;
        };
      }" > "$deployment_dir/inputs.nix"
    nix_inputs=$(< "$deployment_dir/inputs.nix")
    cat > "$deployment_dir/flake.nix" <<EOF
    {
      nixConfig = $nix_config;
      inputs = $nix_inputs;
      outputs = { configuration, ... }: {
        inherit (configuration) darwinConfigurations homeConfigurations;
      };
    }
    EOF

    # A separate lock records the override without modifying the checkout or
    # emitting the expected no-write warning. Both rebuild CLIs accept this flake.
    cp "$repo_root/flake.lock" "$deployment_dir/flake.lock"
    run_command "''${nix_command[@]}" flake lock "$deployment_dir" \
      --override-input host-local "path:$local_inventory" \
      --output-lock-file "$deployment_dir/flake.lock"
    local_flags=(--no-write-lock-file --override-input host-local "path:$local_inventory")
    configuration="$deployment_dir#$configurations.$host"

    if [[ $action == build ]]; then
      run_command "''${nix_command[@]}" build --no-link "$@" "''${local_flags[@]}" \
        "$configuration.$build_attribute"
      exit 0
    fi

    # Resolve the CLI from the selected configuration, including on a fresh machine.
    run_command "''${nix_command[@]}" build --no-link --print-out-paths \
      "''${local_flags[@]}" "$configuration.$cli_attribute" > "$deployment_dir/cli-path"
    cli=$(< "$deployment_dir/cli-path")
    if [[ $configurations == darwinConfigurations ]]; then
      run_command sudo -H "$cli/bin/darwin-rebuild" switch "$@" \
        --flake "$deployment_dir#$host" "''${local_flags[@]}"
    else
      run_command "$cli/bin/home-manager" switch "$@" \
        --flake "$deployment_dir#$host" "''${local_flags[@]}"
    fi
  '';
  meta = {
    description = "Build and activate host environments with local inventory overrides";
    mainProgram = "deploy";
    platforms = lib.platforms.darwin ++ lib.platforms.linux;
  };
}
