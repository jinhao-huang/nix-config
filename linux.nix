{ ... }:
{
  imports = [
    ./modules/linux-development
    ./modules/bash
    ./modules/cli-tools
    ./modules/ssh
    ./modules/tmux
    ./modules/vim
    ./modules/git
    ./modules/gh
    ./modules/starship
    ./modules/zsh
    ./modules/direnv
    ./modules/uv
    ./modules/nix-development
  ];

  home.stateVersion = "26.05";
  home.sessionPath = [ "$HOME/.local/bin" ];

  programs.home-manager.enable = true;

  modules.bash.enable = true;
  modules.cli-tools.enable = true;
  modules.tmux.enable = true;
  modules.vim.enable = true;
  modules.zsh.enable = true;
  modules.direnv.enable = true;
  modules.uv.enable = true;
  modules.nix-development.enable = true;
}
