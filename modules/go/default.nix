{
  config,
  pkgs,
  lib,
  ...
}:

with lib;

let
  cfg = config.modules.go;
in
{
  options.modules.go = {
    enable = mkEnableOption "Go language support";
  };

  config = mkIf cfg.enable {
    programs.go = {
      enable = true;
      package = pkgs.go;
    };
  };
}
