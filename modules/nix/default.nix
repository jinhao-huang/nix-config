{
  config,
  lib,
  pkgs,
  ...
}:

let
  cfg = config.modules.nix;
in
{
  options.modules.nix.enable = lib.mkEnableOption "Nix language tools";

  config = lib.mkIf cfg.enable {
    home.packages = [
      pkgs.nixd
      pkgs.nixfmt
    ];
  };
}
