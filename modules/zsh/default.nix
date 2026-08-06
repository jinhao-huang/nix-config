{
  config,
  lib,
  pkgs,
  ...
}:

{
  options.modules.zsh.enable = lib.mkEnableOption "zsh configuration with vi mode";

  config = lib.mkIf config.modules.zsh.enable {
    programs.zsh = {
      enable = true;

      oh-my-zsh = {
        enable = true;
        plugins = [ "git" ];
      };

      autosuggestion.enable = true;
      syntaxHighlighting.enable = true;

      # Full-featured vi(vim) mode for the command line.
      # Sourced at order 900, after oh-my-zsh (order 800), so its keybindings
      # take precedence. Provides: cursor-shape switching, low ESC latency,
      # text objects, surround (cs/ds/ys), system clipboard, `gx` to open
      # URLs, and `vv` to edit the line in $EDITOR.
      plugins = [
        {
          name = "zsh-vi-mode";
          src = pkgs.zsh-vi-mode;
          file = "share/zsh-vi-mode/zsh-vi-mode.plugin.zsh";
        }
      ];

      initContent = lib.mkOrder 1000 ''
        # Configure zsh-vi-mode via its official zvm_config() hook.
        zvm_config() {
          # Start each new command line in insert mode (default keeps last mode).
          ZVM_LINE_INIT_MODE=$ZVM_MODE_INSERT
        }
      '';
    };
  };
}
