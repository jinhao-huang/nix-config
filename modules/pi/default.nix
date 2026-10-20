{
  config,
  homeManagerUnstable,
  lib,
  ...
}:
let
  cfg = config.modules.pi;
in
{
  _class = "homeManager";

  imports = [ "${homeManagerUnstable}/modules/programs/pi-coding-agent.nix" ];

  options.modules.pi = {
    enable = lib.mkEnableOption "Pi coding agent";
    defaults = lib.mkOption {
      type = import ./startup-defaults-type.nix { inherit lib; };
      default = { };
      description = "Host-specific Pi startup defaults.";
    };
    webSearch.allowRanges = lib.mkOption {
      type = lib.types.listOf lib.types.str;
      default = [ ];
      example = [ "198.18.0.0/15" ];
      description = "IP ranges pi-web-access may fetch despite its SSRF restrictions.";
    };
  };

  config = lib.mkIf cfg.enable {
    home.sessionVariables.PI_SKIP_VERSION_CHECK = "1";

    programs.pi-coding-agent = {
      enable = true;

      settings = {
        defaultProjectTrust = "ask";
        enableInstallTelemetry = false;

        npmCommand = config.modules.mise.commands.npm;

        packages = [
          # Web search, URL fetching, PDF extraction, and video analysis.
          "npm:pi-web-access@0.42.0"
        ];
      }
      // lib.optionalAttrs (cfg.defaults.model != null) {
        defaultProvider = cfg.defaults.model.provider;
        defaultModel = cfg.defaults.model.id;
      }
      // lib.optionalAttrs (cfg.defaults.thinkingLevel != null) {
        defaultThinkingLevel = cfg.defaults.thinkingLevel;
      };
    };

    # pi-web-access has no native Home Manager configuration option.
    home.file.".pi/agent/web-search.json".text = builtins.toJSON (
      {
        # "auto-summary" returns a model-generated summary without the curator
        # window or manual approval; use "none" for raw results.
        workflow = "auto-summary";
      }
      // lib.optionalAttrs (cfg.webSearch.allowRanges != [ ]) {
        ssrf.allowRanges = cfg.webSearch.allowRanges;
      }
    );
  };
}
