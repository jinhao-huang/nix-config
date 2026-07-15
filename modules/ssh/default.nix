{
  config,
  inputs,
  lib,
  pkgs,
  ...
}:

let
  identities = import ./inventory.nix;
  protonPassCli = inputs.self.packages.${pkgs.stdenv.hostPlatform.system}.proton-pass-cli;
  agentSocket = "${config.home.homeDirectory}/.ssh/proton-pass-agent.sock";
  publicKeyDirectory = "${config.home.homeDirectory}/.ssh/proton-pass";

  syncCommands = lib.concatStringsSep "\n" (
    lib.mapAttrsToList (
      name: identity: "sync_key ${lib.escapeShellArg name} ${lib.escapeShellArg identity.reference}"
    ) identities
  );

  syncProtonPassSshKeys = pkgs.writeShellApplication {
    name = "proton-pass-ssh-sync";
    runtimeInputs = [
      pkgs.coreutils
      pkgs.openssh
      protonPassCli
    ];
    text =
      if identities == { } then
        ''
          echo "No Proton Pass SSH keys are configured." >&2
          exit 1
        ''
      else
        ''
          umask 077

          cache_directory=${lib.escapeShellArg publicKeyDirectory}
          mkdir -p "$cache_directory"
          chmod 700 "$cache_directory"

          temporary_key=""
          cleanup() {
            if [[ -n "$temporary_key" ]]; then
              rm -f "$temporary_key"
            fi
          }
          trap cleanup EXIT
          trap 'exit 129' HUP
          trap 'exit 130' INT
          trap 'exit 143' TERM

          sync_key() {
            local name="$1"
            local reference="$2"
            local target="$cache_directory/$name.pub"
            local line
            local -a key_lines=()

            temporary_key="$(mktemp "$cache_directory/.$name.XXXXXX")"
            if ! pass-cli item view "$reference" --output human >"$temporary_key"; then
              echo "Failed to read the Proton Pass public key: $name" >&2
              return 1
            fi

            while IFS= read -r line || [[ -n "$line" ]]; do
              if [[ -n "$line" ]]; then
                key_lines+=("$line")
              fi
            done <"$temporary_key"

            if [[ "''${#key_lines[@]}" -ne 1 ]]; then
              echo "Expected exactly one public key line: $name" >&2
              return 1
            fi

            printf '%s\n' "''${key_lines[0]}" >"$temporary_key"
            if ! ssh-keygen -lf "$temporary_key" -E sha256 >/dev/null; then
              echo "Proton Pass returned an invalid SSH public key: $name" >&2
              return 1
            fi

            chmod 600 "$temporary_key"
            mv -f "$temporary_key" "$target"
            temporary_key=""
            echo "Updated $target"
          }

          ${syncCommands}
        '';
  };

  protonPassSettings = lib.foldl' (hosts: identityHosts: hosts // identityHosts) { } (
    lib.mapAttrsToList (
      identityName: identity:
      lib.mapAttrs (
        _: host:
        {
          ForwardAgent = false;
        }
        // host
        // {
          IdentityAgent = agentSocket;
          IdentityFile = "${publicKeyDirectory}/${identityName}.pub";
          IdentitiesOnly = true;
        }
      ) identity.hosts
    ) identities
  );
in
{
  assertions = lib.mapAttrsToList (name: _: {
    assertion = builtins.match "[A-Za-z0-9._-]+" name != null;
    message = "SSH identity '${name}' is not safe for use as a file name.";
  }) identities;

  home.packages = [ syncProtonPassSshKeys ];

  home.activation.syncProtonPassSshKeys = lib.hm.dag.entryAfter [ "writeBoundary" ] ''
    if [ -z "$DRY_RUN_CMD" ]; then
      if ! ${syncProtonPassSshKeys}/bin/proton-pass-ssh-sync; then
        echo "Warning: Proton Pass SSH public-key sync was incomplete; usable cached keys were preserved." >&2
      fi
    fi
  '';

  programs.ssh = {
    enable = true;
    enableDefaultConfig = false;
    includes = [
      "~/.orbstack/ssh/config"
      "~/.ssh/config.local"
    ];
    settings = protonPassSettings;
  };
}
