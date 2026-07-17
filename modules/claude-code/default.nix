{
  config,
  pkgs,
  lib,
  inputs,
  ...
}:
let
  cfg = config.modules.claude-code;
  system = pkgs.stdenv.hostPlatform.system;
in
{
  options.modules.claude-code = {
    enable = lib.mkEnableOption "Claude Code configuration and aliases";
  };

  config = lib.mkIf cfg.enable {
    # Use the built-in Home Manager module
    programs.claude-code = {
      enable = true;
      package = inputs.llm-agents.packages.${system}."claude-code";
    };
  };
}
