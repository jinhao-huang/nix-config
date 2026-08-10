{ pkgs, ... }:
{
  # Keep Ghostty's terminal definition available to incoming SSH sessions even
  # though the application itself is installed through Homebrew.
  home.packages = [ pkgs.ghostty-bin.terminfo ];

  programs.ghostty = {
    enable = true;
    package = null; # Ghostty is installed through Homebrew on macOS.

    # Disable the cursor feature: it wraps zle-keymap-select/line-finish for
    # cursor switching, conflicting with zsh-vi-mode (same hooks) and
    # zsh-syntax-highlighting (widget wrapping).
    enableZshIntegration = true;
    settings = {
      shell-integration = "detect";
      # Install Ghostty's terminfo on SSH hosts when possible and fall back to
      # xterm-256color when the remote host cannot install it.
      shell-integration-features = "no-cursor,ssh-env,ssh-terminfo";
    };
  };
}
