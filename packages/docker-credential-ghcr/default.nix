{
  lib,
  coreutils,
  gh,
  jq,
  writeShellApplication,
  githubUser,
}:
writeShellApplication {
  name = "docker-credential-ghcr";
  runtimeInputs = [
    coreutils
    gh
    jq
  ];
  text = ''
    github_user=${lib.escapeShellArg githubUser}

    if [[ $# -ne 1 ]]; then
      echo "Usage: docker-credential-ghcr {get|list|store|erase}" >&2
      exit 1
    fi

    case "$1" in
      get|list)
        if [[ $1 == get ]]; then
          server=$(cat)
          if [[ $server != ghcr.io ]]; then
            echo "credentials not found in native keychain"
            exit 1
          fi
        fi
        if ! token=$(gh auth token --hostname github.com --user "$github_user" 2>/dev/null) ||
          [[ -z $token ]]; then
          if [[ $1 == list ]]; then
            echo '{}'
            exit 0
          fi
          echo "No GitHub token for $github_user. Run gh auth login --hostname github.com --web --scopes read:packages as this user."
          exit 1
        fi
        if [[ $1 == list ]]; then
          jq -n --arg username "$github_user" '{"ghcr.io": $username}'
        else
          # Keep the token out of process arguments.
          printf '%s' "$token" | jq -Rs --arg username "$github_user" \
            '{Username: $username, Secret: .}'
        fi
        ;;
      store|erase)
        cat >/dev/null
        echo "Credentials are managed by gh. Use gh auth login or gh auth logout --hostname github.com --user $github_user."
        exit 1
        ;;
      *)
        echo "Unsupported credential helper action: $1" >&2
        exit 1
        ;;
    esac
  '';
  meta = {
    description = "Docker credential helper using a named GitHub CLI account for GHCR";
    mainProgram = "docker-credential-ghcr";
    platforms = lib.platforms.darwin ++ lib.platforms.linux;
  };
}
