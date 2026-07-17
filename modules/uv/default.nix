{
  config,
  lib,
  ...
}:
let
  cfg = config.modules.uv;
in
{
  options.modules.uv = {
    enable = lib.mkEnableOption "uv package manager";
  };

  config = lib.mkIf cfg.enable {
    programs.uv = {
      enable = true;
    };
  };
}
