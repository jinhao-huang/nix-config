{
  config,
  hermesAgent,
  lib,
  pkgs,
  ...
}:
let
  cfg = config.services.hermes-agent;
  common = import "${hermesAgent}/nix/moduleCommon.nix" { inherit lib; };
  rendered = common.mkConfigFiles {
    inherit pkgs cfg;
    workingDirectory = cfg.workingDirectory;
  };
  validationPolicy = pkgs.writeText "hermes-validation.json" (
    builtins.toJSON {
      inherit (cfg) configFile environment environmentFiles;
    }
  );
in
{
  _class = "homeManager";

  imports = [ hermesAgent.homeManagerModules.default ];

  config = lib.mkIf cfg.enable {
    assertions = [
      (lib.hm.assertions.assertPlatform "services.hermes-agent" pkgs [
        "aarch64-darwin"
        "aarch64-linux"
        "x86_64-linux"
      ])
      {
        assertion = lib.all (
          path: lib.hasPrefix "/" path && !(lib.hasPrefix "${builtins.storeDir}/" path)
        ) cfg.environmentFiles;
        message = "Hermes environmentFiles must be absolute runtime paths outside the Nix store.";
      }
    ];

    programs.hermes-agent.enable = true;
    # Use the official renderer, including its schema version, but replace the
    # whole file so removing a declarative key also removes it from runtime state.
    services.hermes-agent.configFile = lib.mkDefault rendered.generated;

    # Upstream rewrites .env and only warns about unreadable inputs. Check all
    # prerequisites before the write boundary to preserve a usable generation.
    home.activation.validateHermes = lib.hm.dag.entryBefore [ "writeBoundary" ] ''
      ${config.programs.hermes-agent.package.hermesVenv}/bin/python3 ${./validate.py} ${validationPolicy}
    '';
  };
}
