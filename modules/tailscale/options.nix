{ config, lib, ... }:
let
  cfg = config.modules.tailscale;
in
{
  options.modules.tailscale = {
    enable = lib.mkEnableOption "a userspace Tailscale daemon";

    incoming.enable = lib.mkEnableOption "incoming tailnet connections to local services";

    ssh.enable = lib.mkEnableOption "Tailscale SSH";
  };

  config = lib.mkIf cfg.enable {
    assertions = [
      {
        assertion = cfg.ssh.enable -> cfg.incoming.enable;
        message = "modules.tailscale.ssh.enable requires modules.tailscale.incoming.enable.";
      }
    ];
  };
}
