{
  config,
  lib,
  pkgs,
  ...
}:
{
  options.modules.cli-tools.enable = lib.mkEnableOption "common command-line tools";

  config = lib.mkIf config.modules.cli-tools.enable {
    programs = {
      ripgrep.enable = true;
      fd.enable = true;
      bat.enable = true;
      fzf.enable = true;
      zoxide.enable = true;
    };

    home.packages = [
      pkgs.curl
      pkgs.rsync
      pkgs.jq
      pkgs.htop
      pkgs.ncdu
      pkgs.lsof
      pkgs.file
      pkgs.unzip
      pkgs.openssh
    ];
  };
}
