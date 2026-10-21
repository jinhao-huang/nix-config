{ pkgs }:
let
  python = pkgs.python3.withPackages (ps: [
    ps.jsonschema
    ps.markdown-it-py
    ps.pyyaml
  ]);
in
pkgs.runCommand "ai-agent-skills-check" { nativeBuildInputs = [ python ]; } ''
  python ${./..}/checks/test-validate-skills.py
  python ${./..}/checks/validate-skills.py
  touch "$out"
''
