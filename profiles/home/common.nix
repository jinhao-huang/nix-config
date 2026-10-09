{ ... }:
{
  imports = [
    ../../modules/bash
    ../../modules/cli-tools
    ../../modules/ssh
    ../../modules/tmux
    ../../modules/vim
    ../../modules/git
    ../../modules/gh
    ../../modules/starship
    ../../modules/zsh
    ../../modules/direnv
    ../../modules/uv
    ../../modules/nix
  ];

  home.sessionPath = [ "$HOME/.local/bin" ];
  programs.home-manager.enable = true;

  modules.cli-tools.enable = true;
  modules.tmux.enable = true;
  modules.vim.enable = true;
  modules.zsh.enable = true;
  modules.direnv.enable = true;
  modules.uv.enable = true;
  modules.nix.enable = true;
}
