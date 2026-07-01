{
  config,
  lib,
  self,
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
          pkgs,
          lib,
          ...
        }:
        {
          config = lib.mkIf (osConfig.modules.proton-pass.enable or false) {
            home.packages = [
              self.packages.${pkgs.stdenv.hostPlatform.system}.proton-pass-cli
            ];
          };
        }
      )
    ];
  };
}
