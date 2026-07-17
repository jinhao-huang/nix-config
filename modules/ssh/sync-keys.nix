{
  identities,
  lib,
  pkgs,
  protonPassCli,
  publicKeyDirectory,
}:

let
  syncCommands = lib.concatStringsSep "\n" (
    lib.mapAttrsToList (
      name: identity: "sync_key ${lib.escapeShellArg name} ${lib.escapeShellArg identity.reference}"
    ) identities
  );
in
pkgs.writeShellApplication {
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
}
