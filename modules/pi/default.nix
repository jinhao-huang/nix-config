{
  config,
  homeManagerUnstable,
  lib,
  llmAgentPackages,
  ...
}:
let
  cfg = config.modules.pi;
in
{
  imports = [ "${homeManagerUnstable}/modules/programs/pi-coding-agent.nix" ];

  options.modules.pi = {
    enable = lib.mkEnableOption "Pi coding agent";

    package = lib.mkPackageOption llmAgentPackages "pi" {
      pkgsText = "llmAgentPackages";
    };
  };

  config = lib.mkIf cfg.enable {
    home.sessionVariables.PI_SKIP_VERSION_CHECK = "1";

    programs.pi-coding-agent = {
      enable = true;
      package = cfg.package;
      context = ../ai-agents/global-guidelines.md;

      settings = {
        defaultProjectTrust = "ask";
        enableInstallTelemetry = false;

        defaultProvider = "zai-coding-cn";
        defaultModel = "glm-5.2";
        defaultThinkingLevel = "medium";

        npmCommand = [
          "${lib.getExe config.modules.mise.package}"
          "exec"
          "node@${config.modules.mise.nodeVersion}"
          "--"
          "npm"
        ];

        packages = [
          # Web search, URL fetching, PDF extraction, and video analysis.
          "npm:pi-web-access@0.20.0"
        ];
      };
    };

    # Read-only store symlink: edit here and redeploy to change.
    home.file.".pi/web-search.json".text = builtins.toJSON {
      # "auto-summary" returns a model-generated summary without the curator
      # window or manual approval; use "none" for raw results.
      workflow = "auto-summary";
      # Exempt the Surge TUN/fake-IP range (RFC 2544 198.18.0.0/15) from the
      # pi-web-access SSRF guard, otherwise every fetch/web_search is blocked.
      ssrf.allowRanges = [ "198.18.0.0/15" ];
    };
  };
}
