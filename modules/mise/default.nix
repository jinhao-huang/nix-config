{
  config,
  pkgs,
  lib,
  ...
}:

with lib;

let
  cfg = config.modules.mise;
in
{
  options.modules.mise = {
    enable = mkEnableOption "mise environment manager";
  };

  config = mkIf cfg.enable {
    programs.mise = {
      enable = true;
      enableBashIntegration = true;
      enableZshIntegration = true;
      globalConfig = {
        tools = {
          "npm:@playwright/cli" = "latest";
        };
      };
    };
  };
}
