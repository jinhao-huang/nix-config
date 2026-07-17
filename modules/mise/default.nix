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
  };

  config = lib.mkIf cfg.enable {
    programs.mise = {
      enable = true;
      package = customPackages.mise;
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
          node = "24";
          pnpm = "11";
          rust = "stable";
        };
      };
    };
  };
}
