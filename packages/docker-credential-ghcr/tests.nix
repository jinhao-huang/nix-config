{ pkgs }:
let
  fakeGh = pkgs.writeShellApplication {
    name = "gh";
    text = ''
      printf '%s\n' "$@" > "$GH_TEST_CALL"
      if [[ ''${GH_TEST_FAIL:-0} == 1 ]]; then
        printf '%s\n' "$GH_TEST_TOKEN"
        printf '%s\n' "$GH_TEST_TOKEN" >&2
        exit 1
      fi
      printf '%s' "$GH_TEST_TOKEN"
    '';
  };
  helper = pkgs.callPackage ./. {
    gh = fakeGh;
    githubUser = "test-user";
  };
in
pkgs.runCommand "docker-credential-ghcr-tests" { nativeBuildInputs = [ pkgs.python3 ]; } ''
  export HELPER=${pkgs.lib.getExe helper}
  python3 ${./tests.py}
  touch "$out"
''
