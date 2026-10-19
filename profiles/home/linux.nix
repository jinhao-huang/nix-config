{
  config,
  lib,
  pkgs,
  ...
}:
let
  ensureLinger = pkgs.writeShellApplication {
    name = "ensure-user-linger";
    runtimeInputs = [
      pkgs.coreutils
      pkgs.systemd
    ];
    text = builtins.readFile ./ensure-linger.sh;
  };
in
{
  imports = [
    ./common.nix
    ../../modules/mise
    ../../modules/pi
    ../../modules/deepseek-harness
    ../../modules/ai-agents
    ../../modules/sing-box
    ../../modules/tailscale/home-manager.nix
  ];

  home.stateVersion = "26.05";
  modules.bash.enable = true;
  modules.mise.enable = true;
  modules.pi.enable = true;
  modules.deepseek-harness = {
    enable = true;
    service = {
      enable = true;
      publicPort = config.modules.tailscale.serve.httpsPort;
    };
  };
  modules.ai-agents = {
    enable = true;
    repoRelativePath = "nix-config";
  };
  modules.sing-box = {
    enable = true;
    listenPort = 21009;
    routing.directDomainSuffixes = [ "internal" ];
  };
  modules.tailscale = {
    enable = true;
    incoming.enable = true;
    outboundProxy.enable = false;
    ssh.enable = true;
    serve = {
      enable = true;
      target = "http://127.0.0.1:${toString config.modules.deepseek-harness.service.proxyPort}";
    };
  };

  systemd.user.services.tailscale-serve.Unit = {
    After = [ "deepseek-harness-proxy.service" ];
    Requires = [ "deepseek-harness-proxy.service" ];
    PartOf = [ "deepseek-harness-proxy.service" ];
  };
  systemd.user.services.tailscale-serve.Install.WantedBy = [ "deepseek-harness-proxy.service" ];

  home.activation.ensureUserLinger =
    lib.hm.dag.entryBetween [ "prepareSingBox" "linkGeneration" "installPackages" ] [ "writeBoundary" ]
      ''
        run ${lib.getExe ensureLinger}
      '';

  xdg.enable = true;
  targets.genericLinux = {
    enable = true;
    # GPU integration requires host setup; keep the CLI profile unprivileged.
    gpu.enable = false;
  };

  # Select activation and shell integration tools; the host owns the daemon.
  nix.package = pkgs.lixPackageSets.stable.lix;
  nix.settings.extra-experimental-features = [
    "nix-command"
    "flakes"
  ];

  home.packages = [ pkgs.ncurses ];
  home.sessionSearchVariables.TERMINFO_DIRS = [
    "${config.home.profileDirectory}/share/terminfo"
    "/etc/terminfo"
    "/lib/terminfo"
    "/usr/share/terminfo"
  ];
}
