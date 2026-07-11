{
  config,
  lib,
  pkgs,
  ...
}:

let
  cfg = config.modules.nix-development;
in
{
  options.modules.nix-development.enable = lib.mkEnableOption "Nix development tools";

  config = lib.mkIf cfg.enable {
    home.packages = with pkgs; [
      nixd
      nixfmt
    ];
  };
}
