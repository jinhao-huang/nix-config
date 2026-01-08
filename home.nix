{ config, pkgs, ... }:

let
  userEmail = "me@jinhaohuang.com";
  gitSigningKey = "ssh-ed25519 AAAAC3NzaC1lZDI1NTE5AAAAIFgb0OhbTZQuqxdcczlzlsEbOGUszYHfo+qI/lbQEUqR";
in
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
  programs.home-manager.enable = true;

  imports = [
    ./modules/starship
    ./modules/git
  ];

  home.packages = with pkgs; [
    rustup
    uv
    fnm
    typst
    imagemagick
    svg2pdf
    mas
    nil
    nixfmt-rfc-style
    claude-code
  ];

  programs.vim = {
    enable = true;
    defaultEditor = true;
  };

  programs.zsh = {
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

  programs.zoxide = {
    enable = true;
    enableZshIntegration = true; # Automatically configure Zsh hooks
  };
}
