{
  config,
  inputs,
  lib,
  pkgs,
  ...
}:

let
  cfg = config.modules.proton-pass;
  protonPassCli = inputs.self.packages.${pkgs.stdenv.hostPlatform.system}.proton-pass-cli;
in
{
  options.modules.proton-pass = {
    enable = lib.mkEnableOption "Proton Pass user services";

    sshAgentSocket = lib.mkOption {
      type = lib.types.str;
      default = "${config.home.homeDirectory}/.ssh/proton-pass-agent.sock";
      description = "Path to the Proton Pass SSH agent socket.";
    };
  };

  config = lib.mkIf cfg.enable {
    home.packages = [ protonPassCli ];
    home.sessionVariables.SSH_AUTH_SOCK = cfg.sshAgentSocket;

    launchd.agents.proton-pass-ssh-agent = {
      enable = true;
      config = {
        ProgramArguments = [
          "${protonPassCli}/bin/pass-cli"
          "ssh-agent"
          "start"
          "--socket-path"
          cfg.sshAgentSocket
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
