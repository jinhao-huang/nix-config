{
  config,
  lib,
  pkgs,
  ...
}:
{
  imports = [ ../../modules/hermes ];

  services.hermes-agent = {
    workingDirectory = lib.mkDefault "${config.home.homeDirectory}/hermes-workspace";
    settings = lib.mkBefore {
      updates.check = false;
      auth.adopt_external_logins = false;
      security.allow_lazy_installs = false;
      agent.coding_context = "off";
      terminal.backend = "local";
      skills.external_dirs = [
        (pkgs.linkFarm "hermes-skills" [
          {
            name = "research";
            path = ../../modules/ai-agents/skills/research;
          }
          {
            name = "humanizer-zh";
            path = ../../modules/ai-agents/skills/humanizer-zh;
          }
        ])
      ];
    };
  };
}
