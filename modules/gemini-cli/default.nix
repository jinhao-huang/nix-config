{
  config,
  lib,
  llmAgentPackages,
  ...
}:
{
  options.modules.gemini-cli.enable = lib.mkEnableOption "Gemini CLI with repository defaults";

  config = lib.mkIf config.modules.gemini-cli.enable {
    programs.antigravity-cli = {
      enable = true;
      package = lib.mkDefault llmAgentPackages.gemini-cli;
    };
  };
}
