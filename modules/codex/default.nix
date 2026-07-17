{
  config,
  lib,
  llmAgentPackages,
  ...
}:
let
  cfg = config.modules.codex;
in
{
  options.modules.codex = {
    enable = lib.mkEnableOption "Codex";
  };

  config = lib.mkIf cfg.enable {
    programs.codex = {
      enable = true;
      package = llmAgentPackages.codex;
    };
  };
}
