{
  config,
  lib,
  pkgs,
  ...
}:
let
  cfg = config.modules.tailscale;
  proxyAddress = "127.0.0.1:1055";
  settings = import ./settings.nix {
    incomingEnabled = cfg.incoming.enable;
    sshEnabled = cfg.ssh.enable;
  };

  # Home Manager has tray clients but no native tailscaled service module.
  tailscaleConfig = (pkgs.formats.json { }).generate "tailscale-user.json" (
    settings // { netfilterMode = "off"; }
  );

  userClient = pkgs.writeShellApplication {
    name = "tailscale-user";
    text = ''
      exec ${lib.getExe' pkgs.tailscale "tailscale"} \
        --socket="''${XDG_RUNTIME_DIR:?XDG_RUNTIME_DIR is not set}/tailscale/tailscaled.sock" "$@"
    '';
  };
in
{
  _class = "homeManager";

  imports = [ ./options.nix ];

  options.modules.tailscale.outboundProxy.enable =
    lib.mkEnableOption "a local SOCKS5 and HTTP proxy for outgoing tailnet connections";

  config = lib.mkIf cfg.enable {
    assertions = [
      (lib.hm.assertions.assertPlatform "modules.tailscale" pkgs lib.platforms.linux)
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
