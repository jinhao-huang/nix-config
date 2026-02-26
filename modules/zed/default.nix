{
  config,
  lib,
  pkgs,
  ...
}:

with lib;

let
  cfg = config.modules.zed;
in
{
  options.modules.zed = {
    enable = mkEnableOption "zed";
  };

  config = mkIf cfg.enable {
    xdg.configFile."zed/settings.json".source =
      config.lib.file.mkOutOfStoreSymlink "${config.modules.repoPath}/modules/zed/settings.json";
    xdg.configFile."zed/keymap.json".source =
      config.lib.file.mkOutOfStoreSymlink "${config.modules.repoPath}/modules/zed/keymap.json";
  };
}
