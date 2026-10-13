{
  config,
  lib,
  pkgs,
  ...
}:
let
  cfg = config.modules.tailscale;
  proxyAddress = "127.0.0.1:1055";

  # Home Manager has tray clients but no native tailscaled service module.
  tailscaleConfig = (pkgs.formats.json { }).generate "tailscale-user.json" {
    version = "alpha0";
    locked = true;
    enabled = true;
    acceptDNS = false;
    acceptRoutes = false;
    runSSHServer = cfg.ssh.enable;
    runWebClient = false;
    shieldsUp = !cfg.incoming.enable;
    exitNode = "";
    advertiseRoutes = [ ];
    netfilterMode = "off";
    autoUpdate = {
      check = false;
      apply = false;
    };
  };

  userClient = pkgs.writeShellApplication {
    name = "tailscale-user";
    text = ''
      exec ${lib.getExe' pkgs.tailscale "tailscale"} \
        --socket="''${XDG_RUNTIME_DIR:?XDG_RUNTIME_DIR is not set}/tailscale/tailscaled.sock" "$@"
    '';
  };
in
{
  options.modules.tailscale = {
    enable = lib.mkEnableOption "an unprivileged userspace Tailscale daemon";

    incoming.enable = lib.mkEnableOption "incoming tailnet connections to local services";

    outboundProxy.enable = lib.mkEnableOption "a local SOCKS5 and HTTP proxy for outgoing tailnet connections";

    ssh.enable = lib.mkEnableOption "Tailscale SSH for the daemon's own Unix user";
  };

  config = lib.mkIf cfg.enable {
    assertions = [
      (lib.hm.assertions.assertPlatform "modules.tailscale" pkgs lib.platforms.linux)
      {
        assertion = cfg.ssh.enable -> cfg.incoming.enable;
        message = "modules.tailscale.ssh.enable requires modules.tailscale.incoming.enable.";
      }
    ];

    home.packages = [
      pkgs.tailscale
      userClient
    ];

    systemd.user.services.tailscaled = {
      Unit.Description = "Tailscale userspace networking";
      Service = {
        ExecStart = lib.escapeShellArgs (
          [
            (lib.getExe' pkgs.tailscale "tailscaled")
            "--tun=userspace-networking"
            "--port=0"
            "--statedir=%S/tailscale"
            "--socket=%t/tailscale/tailscaled.sock"
            "--config=${tailscaleConfig}"
          ]
          ++ lib.optionals cfg.outboundProxy.enable [
            "--socks5-server=${proxyAddress}"
            "--outbound-http-proxy-listen=${proxyAddress}"
          ]
        );
        StateDirectory = "tailscale";
        StateDirectoryMode = "0700";
        RuntimeDirectory = "tailscale";
        RuntimeDirectoryMode = "0700";
        UMask = "0077";
        Restart = "on-failure";
        RestartSec = 5;
      };
      Install.WantedBy = [ "default.target" ];
    };
  };
}
