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
    ../../modules/sing-box
    ../../modules/tailscale/home-manager.nix
  ];

  home.stateVersion = "26.05";
  modules.bash.enable = true;
  modules.mise.enable = true;
  modules.pi.enable = true;
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
  };

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
