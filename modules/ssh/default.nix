{
  config,
  lib,
  pkgs,
  ...
}:

let
  hosts = import ./inventory.nix;
  cfg = config.modules.ssh;
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
  };

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
