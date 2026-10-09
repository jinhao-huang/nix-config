{ config, lib, ... }:
{
  options.modules.vim.enable = lib.mkEnableOption "Vim as the default editor";

  config = lib.mkIf config.modules.vim.enable {
    programs.vim = {
      enable = true;
      defaultEditor = true;
    };
  };
}
