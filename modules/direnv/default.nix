{
  config,
  lib,
  ...
}:

{
  options.modules.direnv.enable = lib.mkEnableOption "direnv with nix-direnv support";

  config = lib.mkIf config.modules.direnv.enable {
    programs.direnv = {
      enable = true;
      enableZshIntegration = true;
      nix-direnv.enable = true;
    };
  };
}
