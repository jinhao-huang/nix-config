{
  config,
  pkgs,
  lib,
  inputs,
  ...
}:

with lib;

let
  cfg = config.modules.codex;
  system = pkgs.stdenv.hostPlatform.system;
in
{
  options.modules.codex = {
    enable = mkEnableOption "Codex";
  };

  config = mkIf cfg.enable {
    programs.codex = {
      enable = true;
      package = inputs.llm-agents.packages.${system}.codex;
    };
  };
}
