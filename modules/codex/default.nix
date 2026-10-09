{
  config,
  lib,
  ...
}:
{
  options.modules.codex.enable = lib.mkEnableOption "Codex with repository defaults";

  config = lib.mkIf config.modules.codex.enable {
    programs.codex = {
      enable = true;
    };
  };
}
