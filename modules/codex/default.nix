{
  config,
  pkgs,
  lib,
  ...
}:

with lib;

let
  cfg = config.modules.codex;
in
{
  options.modules.codex = {
    enable = mkEnableOption "codex";
  };

  config = mkIf cfg.enable {
    programs.codex = {
      enable = true;
    };
  };
}
