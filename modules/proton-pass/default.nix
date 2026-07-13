{
  config,
  lib,
  self,
  ...
}:

with lib;

let
  cfg = config.modules.proton-pass;
in
{
  options.modules.proton-pass = {
    enable = mkEnableOption "Proton Pass applications";
  };

  config = mkIf cfg.enable {
    homebrew.casks = [
      "proton-pass"
    ];

    home-manager.sharedModules = [
      (
        {
          config,
          osConfig,
          pkgs,
          lib,
          ...
        }:
        let
          protonPassCli = self.packages.${pkgs.stdenv.hostPlatform.system}.proton-pass-cli;
          sshAgentSocket = "${config.home.homeDirectory}/.ssh/proton-pass-agent.sock";
        in
        {
          config = lib.mkIf (osConfig.modules.proton-pass.enable or false) {
            home.packages = [ protonPassCli ];
            home.sessionVariables.SSH_AUTH_SOCK = sshAgentSocket;

            launchd.agents.proton-pass-ssh-agent = {
              enable = true;
              config = {
                ProgramArguments = [
                  "${protonPassCli}/bin/pass-cli"
                  "ssh-agent"
                  "start"
                  "--socket-path"
                  sshAgentSocket
                  "--vault-name"
                  "Dev"
                ];
                RunAtLoad = true;
                KeepAlive = true;
                ProcessType = "Background";
                ThrottleInterval = 30;
              };
            };
          };
        }
      )
    ];
  };
}
