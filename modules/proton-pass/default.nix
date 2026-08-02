{
  config,
  customPackages,
  lib,
  ...
}:

let
  cfg = config.modules.proton-pass;
in
{
  options.modules.proton-pass = {
    enable = lib.mkEnableOption "Proton Pass user services";

    package = lib.mkPackageOption customPackages "proton-pass-cli" {
      pkgsText = "customPackages";
    };

    sshAgentSocket = lib.mkOption {
      type = lib.types.str;
      default = "${config.home.homeDirectory}/.ssh/proton-pass-agent.sock";
      description = "Path to the Proton Pass SSH agent socket.";
    };
  };

  config = lib.mkIf cfg.enable {
    home.packages = [ cfg.package ];
    home.sessionVariables.SSH_AUTH_SOCK = cfg.sshAgentSocket;

    launchd.agents.proton-pass-ssh-agent = {
      enable = true;
      config = {
        ProgramArguments = [
          "${cfg.package}/bin/pass-cli"
          "ssh-agent"
          "start"
          "--socket-path"
          cfg.sshAgentSocket
          "--vault-name"
          "Dev"
        ];
        RunAtLoad = true;
        # Authenticate before the first activation to avoid concurrent session initialization.
        KeepAlive = true;
        ProcessType = "Background";
        ThrottleInterval = 30;
      };
    };
  };
}
