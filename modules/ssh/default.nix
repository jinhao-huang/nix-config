{
  config,
  lib,
  pkgs,
  ...
}:

let
  hosts = import ./inventory.nix;
  cfg = config.modules.ssh;
  authorizedKeys = pkgs.writeText "authorized-keys" (
    lib.concatMapStrings (file: builtins.readFile file + "\n") cfg.authorizedKeyFiles
  );
  installAuthorizedKeys = pkgs.writeShellApplication {
    name = "install-authorized-keys";
    runtimeInputs = [ pkgs.coreutils ];
    text = builtins.readFile ./install-authorized-keys.sh;
  };
  sshSettings = lib.mapAttrs (
    _: host:
    host.settings
    // lib.optionalAttrs (host ? identity) {
      IdentityFile = "${host.identity.publicKey}";
      IdentitiesOnly = true;
    }
    // lib.optionalAttrs (host ? identity && cfg.agentSocket != null) {
      IdentityAgent = cfg.agentSocket;
    }
  ) hosts;
in
{
  options.modules.ssh = {
    includeHosts = lib.mkEnableOption "the personal SSH host inventory";
    agentSocket = lib.mkOption {
      type = lib.types.nullOr lib.types.str;
      default = null;
      description = "Agent socket for inventory identities; null uses SSH_AUTH_SOCK.";
    };
    authorizedKeyFiles = lib.mkOption {
      type = lib.types.nullOr (lib.types.listOf lib.types.path);
      default = null;
      description = ''
        Public key files installed as ~/.ssh/authorized_keys during activation.
        Null leaves the file unmanaged; an empty list installs an empty file.
      '';
    };
  };

  config.home.activation.installAuthorizedKeys = lib.mkIf (cfg.authorizedKeyFiles != null) (
    # home.file links into the store, whose group-writable directory fails
    # OpenSSH StrictModes. Replace the old link before linkGeneration cleanup.
    lib.hm.dag.entryBetween [ "linkGeneration" ] [ "writeBoundary" ] ''
      run ${lib.getExe installAuthorizedKeys} ${
        lib.escapeShellArgs [
          authorizedKeys
          config.home.homeDirectory
        ]
      }
    ''
  );

  config.programs.ssh = {
    enable = true;
    enableDefaultConfig = false;
    includes = lib.optional pkgs.stdenv.isDarwin "~/.orbstack/ssh/config" ++ [
      "~/.ssh/config.local"
    ];
    settings = lib.optionalAttrs cfg.includeHosts sshSettings // {
      "*" = {
        ForwardAgent = false;
        ServerAliveInterval = 30;
        ServerAliveCountMax = 3;
      };
    };
  };
}
