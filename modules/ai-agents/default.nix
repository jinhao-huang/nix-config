{
  config,
  lib,
  options,
  ...
}:
let
  cfg = config.modules.ai-agents;
  aiAgentsDir = "${config.home.homeDirectory}/${cfg.repoRelativePath}/modules/ai-agents";
  mkAiAgentsSymlink =
    relativePath: config.lib.file.mkOutOfStoreSymlink "${aiAgentsDir}/${relativePath}";

  agents = mkAiAgentsSymlink "agents";
  commands = mkAiAgentsSymlink "commands";
  skills = mkAiAgentsSymlink "skills";
  context = lib.concatStringsSep "\n\n" (
    [ (builtins.readFile ./global-guidelines.md) ]
    ++ lib.optional (cfg.environment != "") cfg.environment
  );
in
{
  _class = "homeManager";

  options.modules.ai-agents = {
    enable = lib.mkEnableOption "AI agents configuration (guidance, skills, etc.)";

    repoRelativePath = lib.mkOption {
      type = lib.types.strMatching "[^/].*";
      description = "Path to the configuration repository relative to the home directory.";
    };

    environment = lib.mkOption {
      type = lib.types.lines;
      default = "";
      description = "Machine-specific execution guidance appended to the shared global instructions.";
    };
  };

  config = lib.mkIf cfg.enable {
    programs = {
      claude-code.context = context;
      antigravity-cli.context.GEMINI = context;
      opencode.context = context;
      codex = {
        enable = true;
        # Codex is installed outside Home Manager; manage only its context.
        package = null;
        inherit context;
      };
    }
    // lib.optionalAttrs (options.programs ? pi-coding-agent) {
      pi-coding-agent.context = context;
    };

    # DeepSeek Harness has no native Home Manager context option.
    home.file.".dsh/AGENTS.md".text = context;
    home.file.".agents/skills".source = skills;

    xdg.configFile = lib.mkIf config.programs.opencode.enable {
      "opencode/agents".source = agents;
      "opencode/commands".source = commands;
      "opencode/skills".source = skills;
    };
  };
}
