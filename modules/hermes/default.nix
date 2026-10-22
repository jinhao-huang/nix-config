{
  config,
  hermesAgentModule,
  lib,
  pkgs,
  ...
}:
let
  cfg = config.modules.hermes;
in
{
  _class = "homeManager";

  imports = [ hermesAgentModule ];

  options.modules.hermes.enable = lib.mkEnableOption "Hermes Agent CLI policy";

  config = lib.mkIf cfg.enable {
    assertions = [
      (lib.hm.assertions.assertPlatform "modules.hermes" pkgs [
        "aarch64-darwin"
        "aarch64-linux"
        "x86_64-linux"
      ])
    ];

    programs.hermes-agent.enable = true;
  };
}
