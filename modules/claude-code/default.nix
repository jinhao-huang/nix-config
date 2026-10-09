{
  config,
  lib,
  ...
}:
{
  options.modules.claude-code.enable = lib.mkEnableOption "Claude Code with repository defaults";

  config = lib.mkIf config.modules.claude-code.enable {
    programs.claude-code = {
      enable = true;
    };
  };
}
