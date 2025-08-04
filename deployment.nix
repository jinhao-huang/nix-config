{ pkgs, ... }:

{
  # Set required Home Manager options
  home.username = "root";
  home.homeDirectory = "/home/root";

  home.stateVersion = "24.05";

  # List packages you want to install on Linux
  home.packages = with pkgs; [
    git
  ];
}