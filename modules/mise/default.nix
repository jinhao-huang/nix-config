{
  config,
  customPackages,
  lib,
  ...
}:
let
  cfg = config.modules.mise;
in
{
  options.modules.mise = {
    enable = lib.mkEnableOption "mise environment manager";

    package = lib.mkPackageOption customPackages "mise" {
      pkgsText = "customPackages";
    };

    nodeVersion = lib.mkOption {
      type = lib.types.str;
      default = "24";
      description = "Default Node.js major version managed by mise";
    };
  };

  config = lib.mkIf cfg.enable {
    programs.mise = {
      enable = true;
      package = cfg.package;
      enableBashIntegration = true;
      enableZshIntegration = true;
      globalConfig = {
        settings = {
          npm.package_manager = "pnpm";
          idiomatic_version_file_enable_tools = [
            "node"
            "rust"
          ];
        };
        tools = {
          node = cfg.nodeVersion;
          pnpm = "11";
          rust = "stable";
        };
      };
    };
  };
}
