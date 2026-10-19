{
  lib,
  pkgs,
  home-manager,
}:
let
  moduleEvaluation = home-manager.lib.homeManagerConfiguration {
    inherit pkgs;
    modules = [
      ../../modules/sing-box
      ../../modules/deepseek-harness
      ../../modules/tailscale/home-manager.nix
      {
        home.username = "example";
        home.homeDirectory = if pkgs.stdenv.isDarwin then "/Users/example" else "/home/example";
        home.stateVersion = "26.05";
      }
    ];
  };
  optionDocs = pkgs.nixosOptionsDoc {
    options.modules = lib.getAttrs [
      "sing-box"
      "deepseek-harness"
      "tailscale"
    ] moduleEvaluation.options.modules;
    transformOptions =
      option:
      option
      // {
        declarations = map (
          path:
          let
            sourcePath =
              if builtins.pathExists "${toString path}/default.nix" then
                "${toString path}/default.nix"
              else
                toString path;
            relativePath = lib.removePrefix "${toString ../..}/" sourcePath;
          in
          {
            name = relativePath;
            url = "../${relativePath}";
          }
        ) option.declarations;
      };
  };
  optionIndex = pkgs.writeText "configuration-option-index.md" (
    "\n## Option index\n\n"
    + lib.concatMapStrings (
      name:
      let
        anchor = lib.toLower (lib.replaceStrings [ "." ] [ "" ] name);
      in
      "- [`${name}`](#${anchor})\n"
    ) (builtins.attrNames optionDocs.optionsNix)
    + "\n## Module options\n\n"
  );
  reference =
    pkgs.runCommand "configuration-reference"
      {
        passthru = {
          inherit update;
          tests.up-to-date = check;
        };
      }
      ''
        mkdir -p "$out"
        printf '%s\n' "$(cat ${../../docs/configuration-intro.md} ${optionIndex} ${optionDocs.optionsCommonMark})" > "$out/configuration.md"
        cp ${optionDocs.optionsJSON}/share/doc/nixos/options.json "$out/options.json"
      '';
  update = pkgs.writeShellApplication {
    name = "update-configuration-reference";
    runtimeInputs = [ pkgs.coreutils ];
    text = ''
      if [[ ! -f flake.nix || ! -f docs/configuration-intro.md ]]; then
        echo "Run this command from the nix-config repository root." >&2
        exit 1
      fi
      install -m 0644 ${reference}/configuration.md docs/configuration.md
    '';
  };
  check = pkgs.runCommand "configuration-reference-up-to-date" { } ''
    if ! ${lib.getExe' pkgs.diffutils "diff"} -u ${../../docs/configuration.md} ${reference}/configuration.md; then
      echo "Configuration reference is stale. Run: nix run .#update-configuration-reference" >&2
      exit 1
    fi
    touch "$out"
  '';
in
reference
