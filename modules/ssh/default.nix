{
  config,
  lib,
  ...
}:

let
  hosts = import ./inventory.nix;
  agentSocket = config.modules.proton-pass.sshAgentSocket;
  sshSettings = lib.mapAttrs (
    _: host:
    host.settings
    // {
      ForwardAgent = false;
      IdentityAgent = agentSocket;
      IdentityFile = "${host.identity.publicKey}";
      IdentitiesOnly = true;
    }
  ) hosts;
in
{
  programs.ssh = {
    enable = true;
    enableDefaultConfig = false;
    includes = [
      "~/.orbstack/ssh/config"
      "~/.ssh/config.local"
    ];
    settings = sshSettings;
  };
}
