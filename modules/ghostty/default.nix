{ ... }:
{
  programs.ghostty = {
    enable = true;
    package = null; # Ghostty is installed through Homebrew on macOS.

    # Disable automatic zsh integration because Ghostty 1.3.1, Starship 1.25.1,
    # and zsh-syntax-highlighting 0.8.0 can leave synchronized output mode
    # (DEC private mode 2026) active, making Vim appear blank or frozen.
    # Re-evaluate this workaround after upgrading Ghostty.
    enableBashIntegration = false;
    enableFishIntegration = false;
    enableZshIntegration = false;
    settings.shell-integration = "none";
  };
}
