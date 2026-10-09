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

  config = lib.mkMerge [
    (lib.mkIf cfg.enable {
      # Native context options do not accept live-link derivations as file sources.
      home.file.".claude/CLAUDE.md".source = globalGuidelines;
      home.file.".codex/AGENTS.md".source = globalGuidelines;
      home.file.".agents/skills".source = skills;

      xdg.configFile."opencode/AGENTS.md".source = globalGuidelines;
      xdg.configFile."opencode/agents".source = agents;
      xdg.configFile."opencode/commands".source = commands;
      xdg.configFile."opencode/skills".source = skills;
    })

    # Pi keeps a deployment snapshot independently of the live-link switch.
    (lib.mkIf config.modules.pi.enable {
      programs.pi-coding-agent.context = ./global-guidelines.md;
    })
  ];
}
