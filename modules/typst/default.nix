{
  config,
  pkgs,
  lib,
  ...
}:
let
  cfg = config.modules.typst;
in
{
  options.modules.typst = {
    enable = lib.mkEnableOption "Typst typesetting system";

    package = lib.mkPackageOption pkgs "typst" { };
  };

  config = lib.mkIf cfg.enable {
    home.packages = [ cfg.package ];
  };
}
