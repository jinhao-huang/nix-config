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
  loopbackPorts =
    lib.optional config.modules.sing-box.enable config.modules.sing-box.listenPort
    ++
      lib.optionals
        (config.modules.deepseek-harness.enable && config.modules.deepseek-harness.service.enable)
        [
          config.modules.deepseek-harness.service.port
          config.modules.deepseek-harness.service.proxyPort
        ];
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
    environment = ''
      ## Local Execution Environment

      - Home Manager manages this Linux user environment. The host operating system and Nix daemon remain administrator-owned; use `systemctl --user` for managed user services.
    ''
    + lib.optionalString config.modules.sing-box.enable ''

      ### Network Access

      - For external HTTP/SOCKS access, run commands that support proxy environment variables through `with-proxy COMMAND [ARGUMENT ...]`, for example `with-proxy curl -I https://github.com`. Local-only commands can run normally.
      - The wrapper checks the managed sing-box user service and injects its credentials and bypass list into the child environment. It does not start the service; SSH transports, independent daemons, and tools that ignore proxy environment variables need their own network configuration.
      - If the wrapper reports the proxy unavailable, inspect `systemctl --user status sing-box` and `journalctl --user -u sing-box -n 50 --no-pager` before retrying. Keep credentials and subscription data out of prompts and logs.
    '';
  };
  modules.sing-box.enable = lib.mkDefault true;
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

  assertions = [
    {
      assertion = lib.length (lib.unique loopbackPorts) == lib.length loopbackPorts;
      message = "sing-box, DeepSeek Harness, and its proxy must use distinct loopback ports.";
    }
  ];

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
