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

    package = lib.mkPackageOption llmAgentPackages "codex" {
      pkgsText = "llmAgentPackages";
    };
  };

  config = lib.mkIf cfg.enable {
    programs.codex = {
      enable = true;
      package = cfg.package;
    };
  };
}
