{ pkgs, ... }:
{
  programs.starship = {
    enable = true;
    # Automatically integrate with Zsh (enabled by default, included here for clarity)
    enableZshIntegration = true;

    settings = (builtins.fromTOML (builtins.readFile ./plain-text-symbols.toml)) // {
      add_newline = false;
    };
  };
}
