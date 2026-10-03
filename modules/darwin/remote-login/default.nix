{ darwinHost, ... }:
{
  services.openssh = {
    enable = true;
    extraConfig = ''
      PermitRootLogin no
      PubkeyAuthentication yes
      PasswordAuthentication no
      KbdInteractiveAuthentication no
      AllowUsers ${darwinHost.username}
      UsePAM yes
      # Use nix-darwin's AuthorizedKeysCommand instead of user-managed files.
      AuthorizedKeysFile none
    '';
  };

  users.users.${darwinHost.username}.openssh.authorizedKeys.keyFiles = [
    ../../ssh/public-keys/personal.pub
  ];
}
