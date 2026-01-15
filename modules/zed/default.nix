{
  config,
  lib,
  pkgs,
  ...
}:

with lib;

let
  cfg = config.modules.zed;
in
{
  options.modules.zed = {
    enable = mkEnableOption "zed";
  };

  config = mkIf cfg.enable {
    xdg.configFile."zed/settings.json".source = ./settings.json;
  };
}
