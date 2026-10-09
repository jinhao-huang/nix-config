{
  config,
  lib,
  ...
}:
let
  cfg = config.modules.mise;
  miseCfg = config.programs.mise;
  command =
    tools: executable:
    [
      (lib.getExe miseCfg.package)
      "exec"
    ]
    ++ map (tool: "${tool}@${miseCfg.globalConfig.tools.${tool}}") tools
    ++ [
      "--"
      executable
    ];
in
{
  options.modules.mise = {
    enable = lib.mkEnableOption "mise environment manager";

    commands = {
      npm = lib.mkOption {
        type = lib.types.listOf lib.types.str;
        readOnly = true;
        description = "npm command using the declared Mise package and global Node.js version.";
      };

      pnpm = lib.mkOption {
        type = lib.types.listOf lib.types.str;
        readOnly = true;
        description = "pnpm command using the declared Mise package and global Node.js and pnpm versions.";
      };
    };
  };

  config = lib.mkIf cfg.enable {
    modules.mise.commands = {
      npm = command [ "node" ] "npm";
      pnpm = command [ "node" "pnpm" ] "pnpm";
    };

    programs.mise = {
      enable = true;
      enableBashIntegration = true;
      enableZshIntegration = true;
      globalConfig = {
        settings = {
          idiomatic_version_file_enable_tools = [
            "node"
          ];
          not_found_auto_install = false;
          system_deps = "warn";
        };
        tools = {
          node = lib.mkDefault "24";
          pnpm = lib.mkDefault "11";
        };
      };
    };
  };
}
