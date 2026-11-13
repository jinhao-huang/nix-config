{
  lib,
  package,
  httpsPort,
  target,
  guard ? null,
}:
{
  Unit = {
    Description = "Tailnet HTTPS reverse proxy";
    After = [ "tailscaled.service" ];
    Requires = [ "tailscaled.service" ];
    PartOf = [ "tailscaled.service" ];
    StartLimitIntervalSec = 0;
  };
  Service = {
    ExecStart = lib.escapeShellArgs (
      lib.optional (guard != null) (toString guard)
      ++ [
        (lib.getExe' package "tailscale")
        "--socket=%t/tailscale/tailscaled.sock"
        "serve"
        "--yes"
        "--https=${toString httpsPort}"
        target
      ]
    );
    UMask = "0077";
    NoNewPrivileges = true;
    Restart = "always";
    RestartSec = 5;
  };
  Install.WantedBy = [ "tailscaled.service" ];
}
