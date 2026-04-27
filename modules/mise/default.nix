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
  # Keep mise on unstable while avoiding direnv's flaky macOS fish test.
  direnvPackage = pkgs-unstable.direnv.overrideAttrs (_: {
    doCheck = false;
  });
  misePackage = pkgs-unstable.mise.override {
    direnv = direnvPackage;
  };
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
