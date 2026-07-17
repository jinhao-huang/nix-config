{
  config,
  darwinHost,
  pkgs,
  pkgs-unstable,
  ...
}:

{
  # Home Manager needs a bit of information about you and the
  # paths it should manage.
  home.username = darwinHost.username;
  home.homeDirectory = darwinHost.homeDirectory;

  # This value determines the Home Manager release that your
  # configuration is compatible with. This helps avoid breakage
  # when a new Home Manager release introduces backwards
  # incompatible changes.
  #
  # You can update Home Manager without changing this value. See
  # the Home Manager release notes for a list of state version
  # changes in each release.
  home.stateVersion = "25.05";

  home.sessionPath = [
    "$HOME/.local/bin"
  ];

  # Let Home Manager install and manage itself.
  imports = [
    ./modules/starship
    ./modules/git
    ./modules/ssh
    ./modules/go
    ./modules/claude-code
    ./modules/uv
    ./modules/gemini-cli
    ./modules/codex
    ./modules/opencode
    ./modules/ai-agents
    ./modules/zed
    ./modules/mise
    ./modules/tmux
    ./modules/common
    ./modules/nix-development
  ];

  modules.claude-code.enable = true;
  modules.go.enable = true;
  modules.uv.enable = true;
  modules.gemini-cli.enable = true;
  modules.codex.enable = true;
  modules.opencode.enable = true;
  modules.ai-agents.enable = true;
  modules.zed.enable = true;
  modules.mise.enable = true;
  modules.tmux.enable = true;
  modules.nix-development.enable = true;

  # Configuration repository path relative to home directory
  modules.repoRelativePath = "nix-config";

  home.packages = with pkgs; [
    typst
    _1password-cli
  ];

  programs = {
    home-manager.enable = true;

    ripgrep.enable = true;

    vim = {
      enable = true;
      defaultEditor = true;
    };

    gpg = {
      enable = true;
    };

    zsh = {
      enable = true;

      oh-my-zsh = {
        enable = true;
        plugins = [
          "git"
        ];
      };

      autosuggestion.enable = true; # Enable autosuggestions (gray inline completions)
      syntaxHighlighting.enable = true; # Enable syntax highlighting
    };

    zoxide = {
      enable = true;
      enableZshIntegration = true; # Automatically configure Zsh hooks
    };
  };

}
