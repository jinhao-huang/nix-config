{
  config,
  pkgs,
  pkgs-unstable,
  lib,
  ...
}:

with lib;

let
  cfg = config.modules.mise;
  misePackage = pkgs-unstable.mise;
in
{
  options.modules.mise = {
    enable = mkEnableOption "mise environment manager";
  };

  config = mkIf cfg.enable {
    programs.mise = {
      enable = true;
      package = misePackage;
      enableBashIntegration = true;
      enableZshIntegration = true;
      globalConfig = {
        settings = {
          npm.package_manager = "pnpm";
          idiomatic_version_file_enable_tools = [ "rust" ];
        };
        tools = {
          rust = "stable";
        };
      };
    };
  };
}
