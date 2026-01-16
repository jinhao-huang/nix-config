{ config, pkgs, ... }:

{
  # Home Manager needs a bit of information about you and the
  # paths it should manage.
  home.username = "jinhaohuang";
  home.homeDirectory = "/Users/jinhaohuang";

  # This value determines the Home Manager release that your
  # configuration is compatible with. This helps avoid breakage
  # when a new Home Manager release introduces backwards
  # incompatible changes.
  #
  # You can update Home Manager without changing this value. See
  # the Home Manager release notes for a list of state version
  # changes in each release.
  home.stateVersion = "25.05";

  # Let Home Manager install and manage itself.
  imports = [
    ./modules/starship
    ./modules/git
    ./modules/claude-code
    ./modules/uv
    ./modules/gemini-cli
    ./modules/opencode
    ./modules/ai-agents
    ./modules/zed
    ./modules/common
  ];

  modules.claude-code.enable = true;
  modules.uv.enable = true;
  modules.gemini-cli.enable = true;
  modules.opencode.enable = true;
  modules.ai-agents.enable = true;
  modules.zed.enable = true;

  # Configuration repository path relative to home directory
  modules.repoRelativePath = "nix-config";

  home.packages = with pkgs; [
    rustup
    fnm
    typst
    imagemagick
    svg2pdf
    mas
    nil
    nixfmt
  ];

  programs = {
    home-manager.enable = true;

    vim = {
      enable = true;
      defaultEditor = true;
    };

    zsh = {
      enable = true;

      initContent = ''
        eval "$(fnm env --use-on-cd)"
      '';

      oh-my-zsh = {
        enable = true;
        plugins = [
          "git"
        ];
      };

      autosuggestion.enable = true; # Enable autosuggestions (gray inline completions)
      syntaxHighlighting.enable = true; # Enable syntax highlighting
    };

    direnv = {
      enable = true;
      enableZshIntegration = true;
      nix-direnv.enable = true;
    };

    zoxide = {
      enable = true;
      enableZshIntegration = true; # Automatically configure Zsh hooks
    };
  };

}
