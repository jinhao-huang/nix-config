{
  config,
  pkgs,
  lib,
  inputs,
  ...
}:
let
  cfg = config.modules.codex;
  system = pkgs.stdenv.hostPlatform.system;
in
{
  options.modules.codex = {
    enable = lib.mkEnableOption "Codex";
  };

  config = lib.mkIf cfg.enable {
    programs.codex = {
      enable = true;
      package = inputs.llm-agents.packages.${system}.codex;
    };
  };
}
