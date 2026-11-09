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
    serveEnabled = cfg.serve.enable;
  };

  # Home Manager has tray clients but no native tailscaled service module.
  tailscaleConfig = (pkgs.formats.json { }).generate "tailscale-user.json" (
    settings
    // {
      netfilterMode = "off";
    }
  );

  userClient = pkgs.writeShellApplication {
    name = "tailscale-user";
    text = ''
      exec ${lib.getExe' cfg.package "tailscale"} \
        --socket="''${XDG_RUNTIME_DIR:?XDG_RUNTIME_DIR is not set}/tailscale/tailscaled.sock" "$@"
    '';
  };
in
{
  _class = "homeManager";

  imports = [ ./options.nix ];

  options.modules.tailscale.outboundProxy.enable = lib.mkEnableOption ''
    a local SOCKS5 and HTTP proxy for outgoing tailnet connections on
    127.0.0.1:1055. Available on Linux; this does not select an exit node
  '';

  config = lib.mkIf cfg.enable {
    assertions = [
      (lib.hm.assertions.assertPlatform "modules.tailscale" pkgs lib.platforms.linux)
    ];

    home.packages = [
      cfg.package
      userClient
    ];

    systemd.user.services.tailscaled = {
      Unit.Description = "Tailscale userspace networking";
      Service = {
        ExecStart = lib.escapeShellArgs (
          [
            (lib.getExe' cfg.package "tailscaled")
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

    # tailscaled's native config has no node Serve mapping. The foreground CLI
    # owns its mapping for the service lifetime and removes it on disconnect.
    systemd.user.services.tailscale-serve = lib.mkIf cfg.serve.enable {
      Unit = {
        Description = "Tailnet HTTPS reverse proxy";
        After = [ "tailscaled.service" ];
        Requires = [ "tailscaled.service" ];
        PartOf = [ "tailscaled.service" ];
        StartLimitIntervalSec = 0;
      };
      Service = {
        ExecStart = lib.escapeShellArgs [
          (lib.getExe' cfg.package "tailscale")
          "--socket=%t/tailscale/tailscaled.sock"
          "serve"
          "--yes"
          "--https=${toString cfg.serve.httpsPort}"
          cfg.serve.target
        ];
        UMask = "0077";
        NoNewPrivileges = true;
        Restart = "always";
        RestartSec = 5;
      };
      Install.WantedBy = [ "tailscaled.service" ];
    };
  };
}
