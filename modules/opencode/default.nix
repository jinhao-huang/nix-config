{
  config,
  pkgs,
  pkgs-unstable,
  lib,
  ...
}:

with lib;

let
  cfg = config.modules.opencode;
in
{
  options.modules.opencode = {
    enable = mkEnableOption "opencode";
  };

  config = mkIf cfg.enable {
    programs.opencode = {
      enable = true;
      package = pkgs-unstable.opencode;
      settings = {
        plugin = [ "opencode-gemini-auth" ];
        permission = {
          bash = {
            "*" = "ask";
            "ls *" = "allow";
            "grep *" = "allow";
            "cat *" = "allow";
            "find *" = "allow";
            "pwd *" = "allow";
            "git status*" = "allow";
            "git log*" = "allow";
            "git diff*" = "allow";
            "git show*" = "allow";
            "git branch*" = "allow";
            "git commit*" = "deny";
            "git push*" = "deny";
          };
        };
      };
    };
  };
}
