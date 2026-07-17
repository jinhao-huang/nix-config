{
  config,
  lib,
  ...
}:
let
  cfg = config.modules.ai-agents;
  aiAgentsDir = "${config.home.homeDirectory}/${cfg.repoRelativePath}/modules/ai-agents";
  mkAiAgentsSymlink =
    relativePath: config.lib.file.mkOutOfStoreSymlink "${aiAgentsDir}/${relativePath}";

  agents = mkAiAgentsSymlink "agents";
  commands = mkAiAgentsSymlink "commands";
  globalGuidelines = mkAiAgentsSymlink "global-guidelines.md";
  skills = mkAiAgentsSymlink "skills";
in
{
  options.modules.ai-agents = {
    enable = lib.mkEnableOption "AI agents configuration (guidance, skills, etc.)";

    repoRelativePath = lib.mkOption {
      type = lib.types.strMatching "[^/].*";
      description = "Path to the configuration repository relative to the home directory.";
    };
  };

  config = lib.mkIf cfg.enable {
    # Claude Code
    home.file.".claude/CLAUDE.md".source = globalGuidelines;

    # Codex
    home.file.".codex/AGENTS.md".source = globalGuidelines;
    home.file.".agents/skills".source = skills;

    # OpenCode
    xdg.configFile."opencode/AGENTS.md".source = globalGuidelines;
    xdg.configFile."opencode/agents".source = agents;
    xdg.configFile."opencode/commands".source = commands;
    xdg.configFile."opencode/skills".source = skills;
  };
}
