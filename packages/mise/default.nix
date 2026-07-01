{ pkgs }:

let
  version = "2026.6.14";
  system = pkgs.stdenv.hostPlatform.system;
  assets = {
    aarch64-darwin = {
      name = "mise-v${version}-macos-arm64.tar.gz";
      hash = "sha256-bY04m9cp9cRAlKXY6d9cQQrPQwTiVA63mkhUvdItCpE=";
    };
    x86_64-darwin = {
      name = "mise-v${version}-macos-x64.tar.gz";
      hash = "sha256-2o+IcrqWLWiT8Lq2i1qJTKopbx0XwoUMpAdplEG0SyY=";
    };
    aarch64-linux = {
      name = "mise-v${version}-linux-arm64-musl.tar.gz";
      hash = "sha256-lHVB2CaEcyzycyfQ0ZFLRxwO217W24UH+BtK2LZ7p88=";
    };
    x86_64-linux = {
      name = "mise-v${version}-linux-x64-musl.tar.gz";
      hash = "sha256-SR3TH/HgIBx4ZgRvQRASU5KkgfD9N+AeXmIvoSZwt3s=";
    };
  };
  asset = assets.${system} or (throw "mise is not available for ${system}");
in
pkgs.stdenvNoCC.mkDerivation {
  pname = "mise";
  inherit version;

  src = pkgs.fetchurl {
    url = "https://github.com/jdx/mise/releases/download/v${version}/${asset.name}";
    hash = asset.hash;
  };

  sourceRoot = "mise";

  installPhase = ''
    runHook preInstall

    install -Dm755 bin/mise $out/bin/mise
    install -Dm644 LICENSE $out/share/doc/mise/LICENSE
    install -Dm644 README.md $out/share/doc/mise/README.md
    cp -R man $out/share/man
    cp -R share $out/share

    runHook postInstall
  '';

  meta = with pkgs.lib; {
    description = "Polyglot runtime manager, task runner, and environment manager";
    homepage = "https://mise.jdx.dev";
    license = licenses.mit;
    mainProgram = "mise";
    platforms = builtins.attrNames assets;
  };
}
