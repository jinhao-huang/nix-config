{
  pkgs,
  lib,
  config,
  inputs,
  ...
}:

{
  options.modules.tmux.enable = lib.mkEnableOption "tmux configuration";

  config = lib.mkIf config.modules.tmux.enable {
    home.packages = [ pkgs.tmux ];

    xdg.configFile."tmux/tmux.conf".source = "${inputs.oh-my-tmux}/.tmux.conf";

    xdg.configFile."tmux/tmux.conf.local".text =
      builtins.readFile "${inputs.oh-my-tmux}/.tmux.conf.local"
      + ''
        # ==============================================
        # Local Overrides (Managed by Nix)
        # ==============================================
      '';
  };
}
