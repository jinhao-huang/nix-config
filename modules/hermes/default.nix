{
  config,
  hermesAgent,
  lib,
  pkgs,
  ...
}:
let
  cfg = config.services.hermes-agent;
  inherit (config.modules.hermes) namedProfiles protonPassReferences;
  hasProtonPass = protonPassReferences != { };
  secretTemplate = pkgs.writeText "hermes-secrets.env.template" (
    lib.concatLines (lib.mapAttrsToList (name: ref: "${name}={{ ${ref} }}") protonPassReferences)
  );
  secretInput = lib.optionalString hasProtonPass ''<<< "''${hermesProtonPassEnv-}"'';
  serviceNames =
    lib.optional cfg.gateway.enable "hermes-agent"
    ++ lib.optional (cfg.backend.mode != "none") "hermes-backend";
  common = import "${hermesAgent}/nix/moduleCommon.nix" { inherit lib; };
  renderConfig =
    state:
    (common.mkConfigFiles {
      inherit pkgs;
      cfg = state;
      inherit (state) workingDirectory;
    }).generated;
  profileStates = lib.mapAttrs (
    name: profile:
    let
      state = cfg // {
        inherit (profile) settings workingDirectory;
        hermesHome = "${cfg.hermesHome}/profiles/${name}";
        documents = { };
        hermesHomeFiles = {
          "SOUL.md" = profile.soul;
          ".no-bundled-skills" = "1";
        };
        authFile = null;
        extraPlugins = [ ];
      };
    in
    state // { configFile = renderConfig state; }
  ) namedProfiles;
  # Keep upstream documents, auth seeding and plugin handling. The local runtime
  # owns .env so an empty environment also revokes previously installed values.
  setupHome =
    state:
    common.mkStateScript {
      inherit pkgs;
      cfg = state // {
        environment = { };
        environmentFiles = [ ];
      };
      inherit (state) hermesHome workingDirectory;
      stateDirs = common.stateSubdirs;
      managedSystem = "home-manager";
      modes = {
        config = "0600";
        managed = "0600";
        auth = "0600";
        document = "0600";
      };
    };
  stateSetup = pkgs.writeShellScript "hermes-state-setup" ''
    set -eu
    export PATH=${
      lib.makeBinPath [
        pkgs.coreutils
        pkgs.findutils
      ]
    }
    ${lib.concatMapStringsSep "\n" setupHome ([ cfg ] ++ builtins.attrValues profileStates)}
  '';
  runtimePolicy = pkgs.writeText "hermes-runtime.json" (
    builtins.toJSON {
      inherit (cfg)
        configFile
        environment
        environmentFiles
        hermesHome
        ;
      protonPassKeys = builtins.attrNames protonPassReferences;
      namedProfiles = lib.mapAttrs (name: profile: {
        inherit (profileStates.${name}) configFile;
        inherit (profile) environmentKeys;
      }) namedProfiles;
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

  options.modules.hermes.protonPassReferences = lib.mkOption {
    type = lib.types.attrsOf lib.types.singleLineStr;
    default = { };
    description = "Environment variables resolved from Proton Pass references at activation.";
  };
  options.modules.hermes.namedProfiles = lib.mkOption {
    internal = true;
    default = { };
    description = "Named profiles provisioned under the managed Hermes home.";
    type = lib.types.attrsOf (
      lib.types.submodule {
        options = {
          settings = lib.mkOption { type = common.deepConfigType; };
          workingDirectory = lib.mkOption { type = lib.types.str; };
          soul = lib.mkOption { type = lib.types.lines; };
          environmentKeys = lib.mkOption { type = lib.types.listOf lib.types.str; };
        };
      }
    );
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
      {
        assertion = lib.all (
          name: name != "default" && builtins.match "[a-z0-9][a-z0-9_-]{0,63}" name != null
        ) (builtins.attrNames namedProfiles);
        message = "Hermes named profiles must have valid non-default profile names.";
      }
    ];

    programs.hermes-agent.enable = true;
    # Use the official renderer, including its schema version, but replace the
    # whole file so removing a declarative key also removes it from runtime state.
    services.hermes-agent.configFile = lib.mkDefault (renderConfig cfg);
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
      ${lib.optionalString hasProtonPass "run "}${config.programs.hermes-agent.package.hermesVenv}/bin/python3 ${./.}/validate.py ${runtimePolicy} ${secretInput}
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
