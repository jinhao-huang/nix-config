{ pkgs }:

let
  version = "2.2.1";
  system = pkgs.stdenv.hostPlatform.system;
  assets = {
    aarch64-darwin = {
      name = "pass-cli-macos-aarch64";
      hash = "sha256-+v1y8gxFy4Fnk/SNhiPObrnQZHhDGSN2fTZ3b96LRQ4=";
    };
    x86_64-darwin = {
      name = "pass-cli-macos-x86_64";
      hash = "sha256-9lpkph6Quup7olbZsUcgFo8EQPWz1jDRbSffNbRVR5o=";
    };
    aarch64-linux = {
      name = "pass-cli-linux-aarch64";
      hash = "sha256-W/qSKyieYTM9cIx1x3qdvX0FbwBMg42CO8lIrN+xpa0=";
    };
    x86_64-linux = {
      name = "pass-cli-linux-x86_64";
      hash = "sha256-+RbPDVhFA0aOTOy0EreGV7VUU4IphBc/y5ZWo9GnjOY=";
    };
  };
  asset = assets.${system} or (throw "proton-pass-cli is not available for ${system}");
in
pkgs.stdenvNoCC.mkDerivation {
  pname = "proton-pass-cli";
  inherit version;

  src = pkgs.fetchurl {
    url = "https://github.com/protonpass/pass-cli/releases/download/${version}/${asset.name}";
    hash = asset.hash;
  };

  dontUnpack = true;

  installPhase = ''
    runHook preInstall

    install -Dm755 $src $out/bin/pass-cli

    runHook postInstall
  '';

  meta = with pkgs.lib; {
    description = "Command-line interface for Proton Pass";
    homepage = "https://github.com/protonpass/pass-cli";
    license = licenses.gpl3Only;
    mainProgram = "pass-cli";
    platforms = builtins.attrNames assets;
  };
}
