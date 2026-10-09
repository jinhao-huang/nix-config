{
  config,
  lib,
  llmAgentPackages,
  ...
}:
{
  options.modules.codex.enable = lib.mkEnableOption "Codex with repository defaults";

  config = lib.mkIf config.modules.codex.enable {
    programs.codex = {
      enable = true;
      package = lib.mkDefault llmAgentPackages.codex;
    };
  };
}
