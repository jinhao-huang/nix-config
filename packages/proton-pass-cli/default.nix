{ pkgs }:

let
  version = "2.2.3";
  system = pkgs.stdenv.hostPlatform.system;
  assets = {
    aarch64-darwin = {
      name = "pass-cli-macos-aarch64";
      hash = "sha256-gxjlrznYmXgCFOxixtHCz9x2KLsgNtuo9yr3TJpjxzI=";
    };
    x86_64-darwin = {
      name = "pass-cli-macos-x86_64";
      hash = "sha256-K6vfr0ut8cQo1mrNeEN35akxLIo1sftt6hnn6wUa6Dk=";
    };
    aarch64-linux = {
      name = "pass-cli-linux-aarch64";
      hash = "sha256-NdBabzetuIJEbu81Rfg3hUVEw8BJ2A3Who/i08/qwMs=";
    };
    x86_64-linux = {
      name = "pass-cli-linux-x86_64";
      hash = "sha256-cYjwKnweeahg9xZq0sNPei5slhJltwZ34nBPIW3Rdtk=";
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

  meta = {
    description = "Command-line interface for Proton Pass";
    homepage = "https://github.com/protonpass/pass-cli";
    license = pkgs.lib.licenses.gpl3Only;
    sourceProvenance = [ pkgs.lib.sourceTypes.binaryNativeCode ];
    mainProgram = "pass-cli";
    platforms = builtins.attrNames assets;
  };
}
