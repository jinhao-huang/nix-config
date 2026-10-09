{ config, lib, ... }:
{
  options.modules.bash.enable = lib.mkEnableOption "Bash configuration";

  config = lib.mkIf config.modules.bash.enable {
    programs.bash = {
      enable = true;
      historyControl = [
        "ignoredups"
        "ignorespace"
      ];
    };
  };
}
