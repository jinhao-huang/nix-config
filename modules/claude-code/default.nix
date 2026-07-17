{
  config,
  lib,
  llmAgentPackages,
  ...
}:
let
  cfg = config.modules.claude-code;
in
{
  options.modules.claude-code = {
    enable = lib.mkEnableOption "Claude Code configuration and aliases";
  };

  config = lib.mkIf cfg.enable {
    # Use the built-in Home Manager module
    programs.claude-code = {
      enable = true;
      package = llmAgentPackages."claude-code";
    };
  };
}
