{
  config,
  customPackages,
  lib,
  pkgs,
  ...
}:

let
  cfg = config.modules.proton-pass;
  gitSshSign = pkgs.writeShellScript "git-ssh-sign" ''
    export SSH_AUTH_SOCK=${lib.escapeShellArg cfg.sshAgentSocket}
    exec ${pkgs.openssh}/bin/ssh-keygen "$@"
  '';
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
    programs.git.signing.signer = "${gitSshSign}";

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
