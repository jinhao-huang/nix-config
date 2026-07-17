{ pkgs }:

pkgs.writeShellApplication {
  name = "opencode-config-inject";

  runtimeInputs = [
    pkgs.coreutils
    pkgs.gnugrep
    pkgs.jq
  ];

  text = ''
    if (( $# != 4 )); then
      echo "Usage: opencode-config-inject PASS_CLI TEMPLATE TARGET LEGACY_TARGET" >&2
      exit 64
    fi

    pass_cli="$1"
    template="$2"
    target="$3"
    legacy_target="$4"

    if ! "$pass_cli" test >/dev/null 2>&1; then
      echo "Warning: Proton Pass is not logged in; preserving the existing OpenCode configuration." >&2
      exit 1
    fi

    umask 077
    temporary_file=""

    cleanup() {
      if [[ -n "$temporary_file" ]]; then
        rm -f "$temporary_file"
      fi
    }

    trap cleanup EXIT
    trap 'exit 129' HUP
    trap 'exit 130' INT
    trap 'exit 143' TERM

    temporary_file="$(mktemp "$target.tmp.XXXXXX")"

    echo "Injecting Proton Pass secrets into opencode/opencode.json..."
    if "$pass_cli" inject \
      --in-file "$template" \
      --out-file "$temporary_file" \
      --force \
      --file-mode 0400 \
      && jq -e . "$temporary_file" >/dev/null \
      && ! grep -q '{{[[:space:]]*pass://' "$temporary_file"; then
      mv -f "$temporary_file" "$target"
      rm -f "$legacy_target"
      temporary_file=""
    else
      echo "Warning: Proton Pass injection failed; preserving the existing OpenCode configuration." >&2
      exit 1
    fi
  '';
}
