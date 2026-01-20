{
  config,
  pkgs,
  lib,
  ...
}:

with lib;

let
  cfg = config.modules.opencode;
in
{
  options.modules.opencode = {
    enable = mkEnableOption "opencode";
  };

  config = mkIf cfg.enable {
    programs.opencode = {
      enable = true;
      settings = {
        plugin = [ "opencode-gemini-auth" ];
        permission = {
          bash = {
            "*" = "ask";
          };
        };
      };
    };
  };
}
