{
  config,
  lib,
  pkgs,
  ...
}:
let
  userName = "Jinhao Huang";
  userEmail = "me@jinhaohuang.com";
  gitSigningKey = "ssh-ed25519 AAAAC3NzaC1lZDI1NTE5AAAAIFgb0OhbTZQuqxdcczlzlsEbOGUszYHfo+qI/lbQEUqR";
  protonPassSocket = "${config.home.homeDirectory}/.ssh/proton-pass-agent.sock";

  gitSshSign = pkgs.writeShellScript "git-ssh-sign" ''
    export SSH_AUTH_SOCK=${lib.escapeShellArg protonPassSocket}
    exec ${pkgs.openssh}/bin/ssh-keygen "$@"
  '';
in
{
  programs.git = {
    enable = true;
    ignores = [ ".DS_Store" ];

    signing = {
      key = "key::${gitSigningKey}";
      signByDefault = true;
    };

    settings = {
      user = {
        name = userName;
        email = userEmail;
      };
      init.defaultBranch = "main";
      push.autoSetupRemote = true;
      gpg = {
        format = "ssh";
        ssh = {
          program = "${gitSshSign}";
          allowedSignersFile = "~/.config/git/allowed_signers";
        };
      };
    };
  };

  xdg.configFile."git/allowed_signers".text = ''
    ${userEmail} ${gitSigningKey}
  '';
}
