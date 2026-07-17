{
  pkgs,
  lib,
  config,
  ohMyTmux,
  ...
}:

{
  options.modules.tmux.enable = lib.mkEnableOption "tmux configuration";

  config = lib.mkIf config.modules.tmux.enable {
    home.packages = [ pkgs.tmux ];

    xdg.configFile."tmux/tmux.conf".source = "${ohMyTmux}/.tmux.conf";

    xdg.configFile."tmux/tmux.conf.local".text = builtins.readFile "${ohMyTmux}/.tmux.conf.local" + ''
      # ==============================================
      # Local Overrides (Managed by Nix)
      # ==============================================
    '';
  };
}
