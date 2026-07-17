{
  config,
  pkgs,
  lib,
  ...
}:
let
  cfg = config.modules.go;
in
{
  options.modules.go = {
    enable = lib.mkEnableOption "Go language support";
  };

  config = lib.mkIf cfg.enable {
    programs.go = {
      enable = true;
      package = pkgs.go;
    };
  };
}
