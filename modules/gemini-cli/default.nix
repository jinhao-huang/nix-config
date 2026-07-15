{
  config,
  pkgs,
  lib,
  inputs,
  ...
}:

with lib;

let
  cfg = config.modules.gemini-cli;
  system = pkgs.stdenv.hostPlatform.system;
in
{
  options.modules.gemini-cli = {
    enable = mkEnableOption "gemini-cli";
  };

  config = mkIf cfg.enable {
    programs.antigravity-cli = {
      enable = true;
      package = inputs.llm-agents.packages.${system}."gemini-cli";
    };
  };
}
