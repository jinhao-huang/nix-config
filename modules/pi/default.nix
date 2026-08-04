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

        npmCommand = [
          "${lib.getExe config.modules.mise.package}"
          "exec"
          "node@${config.modules.mise.nodeVersion}"
          "--"
          "npm"
        ];

        packages = [
          # Web search, URL fetching, PDF extraction, and video analysis.
          "npm:pi-web-access"
        ];
      };
    };
  };
}
