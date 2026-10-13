{ config, pkgs, ... }:
{
  imports = [
    ./common.nix
    ../../modules/tailscale
  ];

  home.stateVersion = "26.05";
  modules.bash.enable = true;
  modules.tailscale = {
    enable = true;
    incoming.enable = true;
    outboundProxy.enable = false;
    ssh.enable = true;
  };

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
