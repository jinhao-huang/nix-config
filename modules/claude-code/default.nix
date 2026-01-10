{
  config,
  pkgs,
  lib,
  inputs,
  ...
}:

with lib;

let
  cfg = config.modules.claude-code;
in
{
  options.modules.claude-code = {
    enable = mkEnableOption "Claude Code configuration and aliases";
  };

  config = mkIf cfg.enable {
    # Define GLM environment config (using 1Password references)
    # Output: ~/.config/claude-code/profiles/glm.env
    xdg.configFile."claude-code/profiles/glm.env".text = ''
      ANTHROPIC_BASE_URL=https://open.bigmodel.cn/api/anthropic
      ANTHROPIC_AUTH_TOKEN=op://Dev/ClaudeCode-GLM/credential
    '';

    # Create Shell Aliases
    programs.zsh.shellAliases = {
      # Inject secrets at runtime using op inject + env to avoid TTY issues with op run
      claude-glm = "env $(op inject --in-file ${config.xdg.configHome}/claude-code/profiles/glm.env | xargs) claude";
    };

    # Ensure 1Password CLI is available
    home.packages = [
      inputs.claude-code.packages.${pkgs.system}.default
      pkgs._1password-cli
    ];
  };
}
