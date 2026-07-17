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
  };
}
