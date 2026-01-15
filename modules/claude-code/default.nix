{
  config,
  pkgs,
  lib,
  inputs,
  ...
}:

with lib;

let
  cfg = config.modules.claude-code;
in
{
  options.modules.claude-code = {
    enable = mkEnableOption "Claude Code configuration and aliases";
  };

  config = mkIf cfg.enable {
    # Use the built-in Home Manager module
    programs.claude-code = {
      enable = true;
      # Use the package from the flake input
      package = inputs.claude-code.packages.${pkgs.stdenv.hostPlatform.system}.default;
    };
  };
}
