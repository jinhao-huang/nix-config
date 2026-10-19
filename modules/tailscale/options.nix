{ config, lib, ... }:
let
  cfg = config.modules.tailscale;
in
{
  options.modules.tailscale = {
    enable = lib.mkEnableOption "a userspace Tailscale daemon";

    incoming.enable = lib.mkEnableOption ''
      incoming tailnet connections to local services. Userspace networking
      forwards ordinary TCP/UDP traffic to loopback; tailnet access rules must
      restrict which peers and ports can connect
    '';

    ssh.enable = lib.mkEnableOption ''
      Tailscale SSH. Requires incoming.enable plus tailnet rules allowing TCP 22
      and SSH access for the local account
    '';
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
