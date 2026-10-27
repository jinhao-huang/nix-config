{ sshKeys }:
{
  iscas-r750xa = {
    system = "x86_64-linux";
    username = "huangjh";
    homeDirectory = "/home/huangjh";
    authorizedKeyFiles = [ sshKeys.cas ];
    dockerGhcr = {
      enable = true;
      githubUser = "jinhao-huang";
    };
    pi = { };
    hermes = {
      enable = true;
      gateway.enable = true;
      environmentFiles = [ "/home/huangjh/.config/hermes/secrets.env" ];
      environment.TELEGRAM_ALLOW_ALL_USERS = "false";
      settings.platforms.telegram.enabled = true;
    };
    deepseekHarness = {
      publicHost = "iscas-r750xa.bison-agama.ts.net";
      port = 3080;
      proxyPort = 3081;
      httpsPort = 443;
    };
    singBox = {
      listenPort = 21009;
      subscription.requestFile = "/home/huangjh/.config/sing-box/subscription.curl";
      routing.directDomainSuffixes = [ "internal" ];
    };
  };
}
