{ pkgs, ... }:
{
  home.packages = [
    pkgs.source-han-sans
    pkgs.source-han-serif
    pkgs.jetbrains-mono
  ];

  # Home Manager installs macOS fonts natively; Linux needs Fontconfig discovery.
  fonts.fontconfig.enable = pkgs.stdenv.hostPlatform.isLinux;
}
