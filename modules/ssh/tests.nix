{ pkgs }:
pkgs.runCommand "ssh-authorized-keys-tests"
  {
    nativeBuildInputs = [
      pkgs.bashNonInteractive
      pkgs.coreutils
      pkgs.python3
    ];
  }
  ''
    python3 ${./.}/tests.py
    touch "$out"
  ''
