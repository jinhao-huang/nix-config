{ pkgs, hermesAgent }:
let
  python = pkgs.python3.withPackages (packages: [
    packages.python-dotenv
    packages.ruamel-yaml
  ]);
in
pkgs.runCommand "hermes-runtime-tests" { nativeBuildInputs = [ python ]; } ''
  export HERMES_SOURCE=${hermesAgent}
  python3 ${./.}/tests.py
  touch "$out"
''
