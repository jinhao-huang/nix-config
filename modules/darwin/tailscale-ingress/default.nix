{
  config,
  lib,
  pkgs,
  ...
}:
let
  cfg = config.modules.tailscale-ingress;
  # The pinned nix-darwin service has no native preference options.
  tailscaleConfig = (pkgs.formats.json { }).generate "tailscale-ingress.json" {
    version = "alpha0";
    locked = true;
    enabled = true;
    acceptDNS = false;
    acceptRoutes = false;
    runSSHServer = true;
    runWebClient = false;
    shieldsUp = false;
    exitNode = "";
    advertiseRoutes = [ ];
    autoUpdate = {
      check = false;
      apply = false;
    };
  };
in
{
  options.modules.tailscale-ingress.enable = lib.mkEnableOption "a userspace Tailscale ingress daemon";

  config = lib.mkIf cfg.enable {
    assertions = [
      {
        assertion = !config.services.tailscale.enable;
        message = "Use modules.tailscale-ingress or services.tailscale, not both.";
      }
    ];

    environment.systemPackages = [ pkgs.tailscale ];

    # The upstream service module also installs /etc/resolver/ts.net.
    # A userspace ingress must leave system routing and DNS to Surge.
    launchd.daemons.tailscale-ingress = {
      command = lib.escapeShellArgs [
        (lib.getExe' pkgs.tailscale "tailscaled")
        "--tun=userspace-networking"
        "--statedir=/var/lib/tailscale-ingress"
        "--config=${tailscaleConfig}"
      ];
      serviceConfig = {
        Label = "com.tailscale.tailscaled";
        UserName = "root";
        RunAtLoad = true;
        KeepAlive = true;
        Umask = 63; # 0077 in octal.
      };
    };
  };
}
