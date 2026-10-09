{ config, pkgs, ... }:
{
  xdg.enable = true;

  targets.genericLinux = {
    enable = true;
    # GPU integration requires host setup; keep the CLI profile unprivileged.
    gpu.enable = false;
  };

  # Use Lix for activation and shell integration without installing a new client
  # or replacing the existing system daemon and its configuration.
  nix.package = pkgs.lix;

  programs.zsh.dotDir = "${config.xdg.configHome}/zsh";
  home.packages = [ pkgs.ncurses ];

  home.sessionSearchVariables.TERMINFO_DIRS = [
    "${config.home.profileDirectory}/share/terminfo"
    "/etc/terminfo"
    "/lib/terminfo"
    "/usr/share/terminfo"
  ];
}
