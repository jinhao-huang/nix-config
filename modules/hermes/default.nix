{
  config,
  hermesAgent,
  lib,
  pkgs,
  ...
}:
let
  cfg = config.services.hermes-agent;
  protonPassReferences = config.modules.hermes.protonPassReferences;
  hasProtonPass = protonPassReferences != { };
  secretTemplate = pkgs.writeText "hermes-secrets.env.template" (
    lib.concatLines (lib.mapAttrsToList (name: ref: "${name}={{ ${ref} }}") protonPassReferences)
  );
  secretInput = lib.optionalString hasProtonPass ''<<< "''${hermesProtonPassEnv-}"'';
  serviceNames =
    lib.optional cfg.gateway.enable "hermes-agent"
    ++ lib.optional (cfg.backend.mode != "none") "hermes-backend";
  common = import "${hermesAgent}/nix/moduleCommon.nix" { inherit lib; };
  rendered = common.mkConfigFiles {
    inherit pkgs cfg;
    workingDirectory = cfg.workingDirectory;
  };
  validationInputs = {
    inherit (cfg) configFile environment environmentFiles;
    protonPassKeys = builtins.attrNames protonPassReferences;
  };
  validationPolicy = pkgs.writeText "hermes-validation.json" (builtins.toJSON validationInputs);
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
    builtins.toJSON (
      validationInputs
      // {
        inherit (cfg) hermesHome;
        inherit stateSetup;
        stateDirs = common.stateSubdirs;
        platform = if pkgs.stdenv.hostPlatform.isDarwin then "darwin" else "linux";
        manager =
          if pkgs.stdenv.hostPlatform.isDarwin then "/bin/launchctl" else config.systemd.user.systemctlPath;
        services = serviceNames;
      }
    )
  );
  runtime = "${config.programs.hermes-agent.package.hermesVenv}/bin/python3 ${./.}/runtime.py ${runtimePolicy}";
in
{
  _class = "homeManager";

  imports = [ hermesAgent.homeManagerModules.default ];

  options.modules.hermes.protonPassReferences = lib.mkOption {
    type = lib.types.attrsOf lib.types.singleLineStr;
    default = { };
    description = "Environment variables resolved from Proton Pass references at activation.";
  };

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

    # Keep resolved credentials in this activation process until state is applied.
    home.activation.validateHermes = lib.hm.dag.entryBefore [ "writeBoundary" ] ''
      ${lib.optionalString hasProtonPass ''
        if [[ ! -v DRY_RUN ]]; then
          hermesProtonPassEnv=$(${lib.getExe' config.modules.proton-pass.package "pass-cli"} inject < ${secretTemplate})
        fi
      ''}
      ${lib.optionalString hasProtonPass "run "}${config.programs.hermes-agent.package.hermesVenv}/bin/python3 ${./.}/validate.py ${validationPolicy} ${secretInput}
    '';

    # Runtime credentials cannot be represented by unit restart triggers. Apply
    # the complete state before either native service manager can start a unit.
    home.activation.hermesAgentSetup = lib.mkForce (
      lib.hm.dag.entryBetween [ "reloadSystemd" "setupLaunchAgents" ] [ "writeBoundary" "linkGeneration" ]
        ''
          run ${runtime} apply ${secretInput}
          ${lib.optionalString hasProtonPass "unset hermesProtonPassEnv"}
        ''
    );
    home.activation.restartHermes =
      lib.hm.dag.entryAfter [ "hermesAgentSetup" "reloadSystemd" "setupLaunchAgents" ]
        ''
          run ${runtime} restart
        '';
  };
}
