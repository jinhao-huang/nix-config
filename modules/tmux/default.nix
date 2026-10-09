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
    home.packages = [
      pkgs.tmux
      pkgs.perl
    ];

    # Oh-my-tmux executes shell code embedded in this file; keep it intact
    # rather than prepending Home Manager's generated tmux configuration.
    xdg.configFile."tmux/tmux.conf".source = "${ohMyTmux}/.tmux.conf";

    xdg.configFile."tmux/tmux.conf.local".text = builtins.readFile "${ohMyTmux}/.tmux.conf.local" + ''
      # ==============================================
      # Local Overrides (Managed by Nix)
      # ==============================================
      set -g default-shell ${lib.escapeShellArg "${pkgs.zsh}/bin/zsh"}
      set -g default-terminal tmux-256color
      set -g history-limit 10000
      set -g mouse on
      set -g mode-keys vi
    '';
  };
}
