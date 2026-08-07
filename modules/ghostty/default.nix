{ ... }:
{
  programs.ghostty = {
    enable = true;
    package = null; # Ghostty is installed through Homebrew on macOS.

    # Disable the cursor feature: it wraps zle-keymap-select/line-finish for
    # cursor switching, conflicting with zsh-vi-mode (same hooks) and
    # zsh-syntax-highlighting (widget wrapping).
    enableZshIntegration = true;
    settings = {
      shell-integration = "detect";
      shell-integration-features = "no-cursor";
    };
  };
}
