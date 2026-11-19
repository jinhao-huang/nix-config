{ sshKeys }:
{
  iscas-r750xa = rec {
    system = "x86_64-linux";
    username = "huangjh";
    homeDirectory = "/home/huangjh";
    tailnetHost = (import ../modules/ssh/inventory.nix).iscas-r750xa.settings.HostName;
    authorizedKeyFiles = [ sshKeys.cas ];
    dockerGhcr = {
      enable = true;
      githubUser = "jinhao-huang";
    };
    pi = { };
    hermesCredentialFile = "${homeDirectory}/.config/nix-config/hermes.env";
    hermes = {
      enable = true;
      backend.mode = "dashboard";
    };
    singBox = {
      listenPort = 21009;
      subscription.requestFile = "${homeDirectory}/.config/sing-box/subscription.curl";
      routing.directDomainSuffixes = [ "internal" ];
    };
  };
}
