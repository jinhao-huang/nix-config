{
  config,
  lib,
  options,
  pkgs,
  ...
}:
let
  cfg = config.modules.ai-agents;
  aiAgentsDir = "${config.home.homeDirectory}/${cfg.repoRelativePath}/modules/ai-agents";
  mkAiAgentsSymlink =
    relativePath: config.lib.file.mkOutOfStoreSymlink "${aiAgentsDir}/${relativePath}";

  agents = mkAiAgentsSymlink "agents";
  commands = mkAiAgentsSymlink "commands";
  bundledSkills = lib.mapAttrs (name: _: mkAiAgentsSymlink "skills/${name}") (
    lib.filterAttrs (_: type: type == "directory") (builtins.readDir ./skills)
  );
  skillSources =
    bundledSkills // lib.mapAttrs (_: config.lib.file.mkOutOfStoreSymlink) cfg.externalSkills;
  skills = pkgs.linkFarm "ai-agent-skills" (
    lib.mapAttrsToList (name: path: { inherit name path; }) skillSources
  );
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

    externalSkills = lib.mkOption {
      type = lib.types.attrsOf (lib.types.strMatching "/.+");
      default = { };
      description = "External skill directories selected by the home profile, keyed by skill name.";
    };
  };

  config = lib.mkIf cfg.enable {
    assertions = [
      {
        assertion = lib.all (
          name: builtins.match "[a-z0-9]+(-[a-z0-9]+)*" name != null && builtins.stringLength name <= 64
        ) (builtins.attrNames cfg.externalSkills);
        message = "External AI skill names must use lowercase kebab-case and be at most 64 characters.";
      }
      {
        assertion = builtins.intersectAttrs bundledSkills cfg.externalSkills == { };
        message = "External AI skills must not replace bundled skills.";
      }
    ];

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

    # Home Manager has no native option for the shared .agents/skills directory.
    home.file.".agents/skills".source = skills;
    # DeepSeek Harness has no native Home Manager context option.
    home.file.".dsh/AGENTS.md".text = context;

    xdg.configFile = lib.mkIf config.programs.opencode.enable {
      "opencode/agents".source = agents;
      "opencode/commands".source = commands;
    };
  };
}
