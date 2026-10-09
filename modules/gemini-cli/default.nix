{
  config,
  lib,
  ...
}:
{
  options.modules.gemini-cli.enable = lib.mkEnableOption "Gemini CLI with repository defaults";

  config = lib.mkIf config.modules.gemini-cli.enable {
    programs.antigravity-cli = {
      enable = true;
    };
  };
}
