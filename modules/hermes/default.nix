{
  config,
  hermesAgent,
  lib,
  pkgs,
  ...
}:
let
  cfg = config.services.hermes-agent;
  serviceNames =
    lib.optional cfg.gateway.enable "hermes-agent"
    ++ lib.optional (cfg.backend.mode != "none") "hermes-backend";
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
  # Keep upstream documents, auth seeding and plugin handling. The local runtime
  # owns .env so an empty environment also revokes previously installed values.
  stateSetup = pkgs.writeShellScript "hermes-state-setup" ''
    set -eu
    export PATH=${
      lib.makeBinPath [
        pkgs.coreutils
        pkgs.findutils
      ]
    }
    ${common.mkStateScript {
      inherit pkgs;
      cfg = cfg // {
        environment = { };
        environmentFiles = [ ];
      };
      inherit (cfg) hermesHome workingDirectory;
      stateDirs = common.stateSubdirs;
      managedSystem = "home-manager";
      modes = {
        config = "0600";
        env = "0600";
        managed = "0600";
        auth = "0600";
        document = "0600";
      };
    }}
  '';
  runtimePolicy = pkgs.writeText "hermes-runtime.json" (
    builtins.toJSON {
      inherit (cfg)
        configFile
        environment
        environmentFiles
        hermesHome
        ;
      inherit stateSetup;
      stateDirs = common.stateSubdirs;
      platform = if pkgs.stdenv.hostPlatform.isDarwin then "darwin" else "linux";
      manager =
        if pkgs.stdenv.hostPlatform.isDarwin then "/bin/launchctl" else config.systemd.user.systemctlPath;
      services = serviceNames;
    }
  );
  runtime = "${config.programs.hermes-agent.package.hermesVenv}/bin/python3 ${./.}/runtime.py ${runtimePolicy}";
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

    launchd.agents = lib.mkIf pkgs.stdenv.hostPlatform.isDarwin (
      lib.genAttrs serviceNames (_: {
        # launchd plists encode the octal 0077 umask as a decimal integer.
        config.Umask = 63;
      })
    );

    # Check prerequisites before the write boundary to preserve a usable
    # generation; the runtime checks them again before applying state.
    home.activation.validateHermes = lib.hm.dag.entryBefore [ "writeBoundary" ] ''
      ${config.programs.hermes-agent.package.hermesVenv}/bin/python3 ${./.}/validate.py ${validationPolicy}
    '';

    # Runtime credentials cannot be represented by unit restart triggers. Apply
    # the complete state before either native service manager can start a unit.
    home.activation.hermesAgentSetup = lib.mkForce (
      lib.hm.dag.entryBetween [ "reloadSystemd" "setupLaunchAgents" ] [ "writeBoundary" "linkGeneration" ]
        ''
          run ${runtime} apply
        ''
    );
    home.activation.restartHermes =
      lib.hm.dag.entryAfter [ "hermesAgentSetup" "reloadSystemd" "setupLaunchAgents" ]
        ''
          run ${runtime} restart
        '';
  };
}
