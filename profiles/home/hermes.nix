{
  config,
  lib,
  pkgs,
  ...
}:
{
  imports = [ ../../modules/hermes ];

  services.hermes-agent = {
    # Reserve the upstream port for HTTPS on the userspace Tailscale node.
    backend.port = lib.mkDefault 19119;
    workingDirectory = lib.mkDefault "${config.home.homeDirectory}/hermes-workspace";
    settings = lib.mkBefore {
      updates.check = false;
      auth.adopt_external_logins = false;
      security.allow_lazy_installs = false;
      agent.coding_context = "off";
      agent.reasoning_overrides.deepseek-flash = "high";
      terminal.backend = "local";
      model = {
        provider = "minimax-cn";
        default = "MiniMax-M3.1-Flash";
      };
      providers.minimax-cn.models."MiniMax-M3.1-Flash".supports_vision = true;
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
