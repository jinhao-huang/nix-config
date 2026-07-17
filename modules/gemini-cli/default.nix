{
  config,
  lib,
  llmAgentPackages,
  ...
}:
let
  cfg = config.modules.gemini-cli;
in
{
  options.modules.gemini-cli = {
    enable = lib.mkEnableOption "gemini-cli";
  };

  config = lib.mkIf cfg.enable {
    programs.antigravity-cli = {
      enable = true;
      package = llmAgentPackages."gemini-cli";
    };
  };
}
