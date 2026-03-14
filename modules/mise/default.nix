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
  playwrightCli = pkgs.writeShellScriptBin "playwright-cli" ''
    exec ${lib.getExe misePackage} exec node@lts npm:@playwright/cli@0.1.1 -- playwright-cli "$@"
  '';
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
      settings = {
        npm.package_manager = "pnpm";
      };
    };

    home.packages = [ playwrightCli ];
  };
}
