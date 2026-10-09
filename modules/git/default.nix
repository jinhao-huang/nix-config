{ ... }:
let
  userName = "Jinhao Huang";
  userEmail = "me@jinhaohuang.com";
  gitSigningKey = "ssh-ed25519 AAAAC3NzaC1lZDI1NTE5AAAAIFgb0OhbTZQuqxdcczlzlsEbOGUszYHfo+qI/lbQEUqR";
in
{
  programs.git = {
    enable = true;
    ignores = [ ".DS_Store" ];

    signing = {
      key = "key::${gitSigningKey}";
      format = "ssh";
      signByDefault = true;
    };

    settings = {
      user = {
        name = userName;
        email = userEmail;
      };
      init.defaultBranch = "main";
      push.autoSetupRemote = true;
      fetch.prune = true;
      pull.ff = "only";
      gpg.ssh.allowedSignersFile = "~/.config/git/allowed_signers";
    };
  };

  xdg.configFile."git/allowed_signers".text = ''
    ${userEmail} ${gitSigningKey}
  '';
}
