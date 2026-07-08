{
  config,
  lib,
  ...
}:

with lib;

let
  cfg = config.modules.ai-agents;
in
{
  options.modules.ai-agents = {
    enable = mkEnableOption "AI agents configuration (rules, skills, etc.)";
  };

  config = mkIf cfg.enable {
    # Link shared agent guidance
    home.file.".claude/CLAUDE.md".source =
      config.lib.file.mkOutOfStoreSymlink "${config.modules.repoPath}/modules/ai-agents/global-guidelines.md";

    home.file.".codex/AGENTS.md".source =
      config.lib.file.mkOutOfStoreSymlink "${config.modules.repoPath}/modules/ai-agents/global-guidelines.md";

    # Link Codex skills
    home.file.".agents/skills".source =
      config.lib.file.mkOutOfStoreSymlink "${config.modules.repoPath}/modules/ai-agents/skills";

    xdg.configFile."opencode/AGENTS.md".source =
      config.lib.file.mkOutOfStoreSymlink "${config.modules.repoPath}/modules/ai-agents/global-guidelines.md";

    # Link OpenCode agents
    xdg.configFile."opencode/agent".source =
      config.lib.file.mkOutOfStoreSymlink "${config.modules.repoPath}/modules/ai-agents/agents";

    # Link OpenCode skills
    xdg.configFile."opencode/skills".source =
      config.lib.file.mkOutOfStoreSymlink "${config.modules.repoPath}/modules/ai-agents/skills";

    # Link OpenCode commands
    xdg.configFile."opencode/commands".source =
      config.lib.file.mkOutOfStoreSymlink "${config.modules.repoPath}/modules/ai-agents/commands";
  };
}
