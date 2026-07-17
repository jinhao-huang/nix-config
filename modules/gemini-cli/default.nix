{
  config,
  pkgs,
  lib,
  inputs,
  ...
}:
let
  cfg = config.modules.gemini-cli;
  system = pkgs.stdenv.hostPlatform.system;
in
{
  options.modules.gemini-cli = {
    enable = lib.mkEnableOption "gemini-cli";
  };

  config = lib.mkIf cfg.enable {
    programs.antigravity-cli = {
      enable = true;
      package = inputs.llm-agents.packages.${system}."gemini-cli";
    };
  };
}
