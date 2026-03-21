{
  config,
  lib,
  ...
}:

with lib;

let
  cfg = config.modules.proton-pass;
in
{
  options.modules.proton-pass = {
    enable = mkEnableOption "Proton Pass applications";
  };

  config = mkIf cfg.enable {
    homebrew.casks = [
      "proton-pass"
    ];

    home-manager.sharedModules = [
      (
        {
          osConfig,
          pkgs-unstable,
          lib,
          ...
        }:
        {
          config = lib.mkIf (osConfig.modules.proton-pass.enable or false) {
            home.packages = [
              pkgs-unstable.proton-pass-cli
            ];
          };
        }
      )
    ];
  };
}
