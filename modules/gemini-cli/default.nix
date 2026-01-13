{
  config,
  pkgs,
  lib,
  ...
}:

with lib;

let
  cfg = config.modules.gemini-cli;
in
{
  options.modules.gemini-cli = {
    enable = mkEnableOption "gemini-cli";
  };

  config = mkIf cfg.enable {
    programs.gemini-cli = {
      enable = true;
    };
  };
}
