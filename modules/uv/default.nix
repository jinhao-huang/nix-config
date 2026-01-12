{
  config,
  pkgs,
  lib,
  ...
}:

with lib;

let
  cfg = config.modules.uv;
in
{
  options.modules.uv = {
    enable = mkEnableOption "uv package manager";
  };

  config = mkIf cfg.enable {
    programs.uv = {
      enable = true;
    };
  };
}
