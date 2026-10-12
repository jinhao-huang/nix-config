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
    # Native context options do not accept live-link derivations as file sources.
    home.file.".claude/CLAUDE.md".source = globalGuidelines;
    home.file.".codex/AGENTS.md".source = globalGuidelines;
    home.file.".agents/skills".source = skills;

    xdg.configFile = lib.mkIf config.programs.opencode.enable {
      "opencode/AGENTS.md".source = globalGuidelines;
      "opencode/agents".source = agents;
      "opencode/commands".source = commands;
      "opencode/skills".source = skills;
    };
  };
}
