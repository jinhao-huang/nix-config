{
  config,
  lib,
  pkgs,
  ...
}:

let
  identities = import ./inventory.nix;
  protonPassCli = config.modules.proton-pass.package;
  agentSocket = config.modules.proton-pass.sshAgentSocket;
  publicKeyDirectory = "${config.home.homeDirectory}/.ssh/proton-pass";

  syncProtonPassSshKeys = import ./sync-keys.nix {
    inherit
      identities
      lib
      pkgs
      protonPassCli
      publicKeyDirectory
      ;
  };

  protonPassSettings = lib.foldl' (hosts: identityHosts: hosts // identityHosts) { } (
    lib.mapAttrsToList (
      identityName: identity:
      lib.mapAttrs (
        _: host:
        {
          ForwardAgent = false;
        }
        // host
        // {
          IdentityAgent = agentSocket;
          IdentityFile = "${publicKeyDirectory}/${identityName}.pub";
          IdentitiesOnly = true;
        }
      ) identity.hosts
    ) identities
  );
in
{
  assertions = lib.mapAttrsToList (name: _: {
    assertion = builtins.match "[A-Za-z0-9._-]+" name != null;
    message = "SSH identity '${name}' is not safe for use as a file name.";
  }) identities;

  home.packages = [ syncProtonPassSshKeys ];

  home.activation.syncProtonPassSshKeys = lib.hm.dag.entryAfter [ "writeBoundary" ] ''
    if [ -z "$DRY_RUN_CMD" ]; then
      if ! ${syncProtonPassSshKeys}/bin/proton-pass-ssh-sync; then
        echo "Warning: Proton Pass SSH public-key sync was incomplete; usable cached keys were preserved." >&2
      fi
    fi
  '';

  programs.ssh = {
    enable = true;
    enableDefaultConfig = false;
    includes = [
      "~/.orbstack/ssh/config"
      "~/.ssh/config.local"
    ];
    settings = protonPassSettings;
  };
}
