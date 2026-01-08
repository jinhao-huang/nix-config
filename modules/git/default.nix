{ pkgs, ... }:
let
  userName = "Jinhao Huang";
  userEmail = "me@jinhaohuang.com";
  gitSigningKey = "ssh-ed25519 AAAAC3NzaC1lZDI1NTE5AAAAIFgb0OhbTZQuqxdcczlzlsEbOGUszYHfo+qI/lbQEUqR";
in
{
  programs.git = {
    enable = true;
    inherit userName userEmail;
    ignores = [ ".DS_Store" ];

    signing = {
      key = gitSigningKey;
      signByDefault = true;
    };

    extraConfig = {
      init.defaultBranch = "main";
      push.autoSetupRemote = true;
      gpg = {
        format = "ssh";
        ssh = {
          program = "/Applications/1Password.app/Contents/MacOS/op-ssh-sign";
          allowedSignersFile = "~/.config/git/allowed_signers";
        };
      };
    };
  };

  # Declaratively generate the allowed_signers file
  xdg.configFile."git/allowed_signers".text = ''
    ${userEmail} ${gitSigningKey}
  '';
}
