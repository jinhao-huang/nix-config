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
    settings
    // {
      netfilterMode = "off";
      # Upstream rejects Serve's runtime mapping API when the native config is
      # locked. Connection preferences still come from this file on startup.
      locked = !cfg.serve.enable;
    }
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

  options.modules.tailscale.serve = {
    enable = lib.mkEnableOption "a tailnet-only HTTPS reverse proxy";
    httpsPort = lib.mkOption {
      type = lib.types.ints.between 1 65535;
      default = 443;
      description = "Tailnet HTTPS port for Tailscale Serve.";
    };
    target = lib.mkOption {
      type = lib.types.strMatching "http://127[.]0[.]0[.]1:[0-9]+";
      description = "Loopback HTTP backend for Tailscale Serve.";
    };
  };

  config = lib.mkIf cfg.enable {
    assertions = [
      (lib.hm.assertions.assertPlatform "modules.tailscale" pkgs lib.platforms.linux)
      {
        assertion = cfg.serve.enable -> cfg.incoming.enable;
        message = "Tailscale Serve requires incoming tailnet connections.";
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
          (lib.getExe' pkgs.tailscale "tailscale")
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
