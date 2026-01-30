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
    # Link Claude Code rules
    home.file.".claude/CLAUDE.md".source =
      config.lib.file.mkOutOfStoreSymlink "${config.modules.repoPath}/modules/ai-agents/rules.md";

    # Link OpenCode rules
    xdg.configFile."opencode/AGENTS.md".source =
      config.lib.file.mkOutOfStoreSymlink "${config.modules.repoPath}/modules/ai-agents/rules.md";

    # Link OpenCode agents
    xdg.configFile."opencode/agent".source =
      config.lib.file.mkOutOfStoreSymlink "${config.modules.repoPath}/modules/ai-agents/agents";

    # Link OpenCode skills
    xdg.configFile."opencode/skills".source =
      config.lib.file.mkOutOfStoreSymlink "${config.modules.repoPath}/modules/ai-agents/skills";
  };
}
