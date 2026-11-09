{
  config,
  lib,
  pkgs,
  ...
}:
let
  cfg = config.modules.tailscale;
in
{
  options.modules.tailscale = {
    enable = lib.mkEnableOption "a userspace Tailscale daemon";

    package = lib.mkPackageOption pkgs "tailscale" { };

    incoming.enable = lib.mkEnableOption ''
      incoming tailnet connections to local services. Userspace networking
      forwards ordinary TCP/UDP traffic to loopback; tailnet access rules must
      restrict which peers and ports can connect
    '';

    ssh.enable = lib.mkEnableOption ''
      Tailscale SSH. Requires incoming.enable plus tailnet rules allowing TCP 22
      and SSH access for the local account
    '';

    serve = {
      enable = lib.mkEnableOption ''
        a tailnet-only HTTPS reverse proxy. Requires incoming.enable,
        MagicDNS, tailnet HTTPS certificates, and access to the selected HTTPS
        port. Enabling Serve unlocks native daemon preferences so the foreground
        CLI can manage its mapping; Nix reapplies preferences on daemon startup
      '';
      httpsPort = lib.mkOption {
        type = lib.types.ints.between 1 65535;
        default = 443;
        example = 8443;
        description = "Tailnet HTTPS port for Tailscale Serve.";
      };
      target = lib.mkOption {
        type = lib.types.strMatching "http://127[.]0[.]0[.]1:[0-9]+";
        example = "http://127.0.0.1:3081";
        description = ''
          Loopback HTTP backend, required when Serve is enabled. The mapping
          lasts for the lifetime of the foreground Serve process.
        '';
      };
    };
  };

  config = lib.mkIf cfg.enable {
    assertions = [
      {
        assertion = cfg.ssh.enable -> cfg.incoming.enable;
        message = "modules.tailscale.ssh.enable requires modules.tailscale.incoming.enable.";
      }
      {
        assertion = cfg.serve.enable -> cfg.incoming.enable;
        message = "Tailscale Serve requires incoming tailnet connections.";
      }
    ];
  };
}
