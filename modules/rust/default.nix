{
  config,
  lib,
  pkgs,
  ...
}:
let
  cfg = config.modules.rust;
in
{
  options.modules.rust = {
    enable = lib.mkEnableOption "Rust language support";
  };

  config = lib.mkIf cfg.enable {
    home.packages = with pkgs; [
      cargo
      clippy
      rust-analyzer
      rustc
      rustfmt
    ];
  };
}
