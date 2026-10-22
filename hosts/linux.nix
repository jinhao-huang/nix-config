{
  iscas-r750xa = {
    system = "x86_64-linux";
    username = "huangjh";
    homeDirectory = "/home/huangjh";
    authorizedKeyFiles = [ ../modules/ssh/public-keys/cas.pub ];
    pi = { };
    tailscaleHostname = "iscas-r750xa.bison-agama.ts.net";
    deepseekHarness = {
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
