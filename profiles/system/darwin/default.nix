{
  config,
  configurationRevision,
  darwinHost,
  lib,
  pkgs,
  ...
}:
let
  hermes = config.home-manager.users.${darwinHost.username}.services.hermes-agent;
  serveHermes =
    darwinHost ? hermesServe
    && darwinHost.hermes.enable
    && (darwinHost.hermes.backend.mode or "none") == "dashboard";
  httpsPort = config.modules.tailscale.serve.httpsPort;
  hermesUrl = "https://${darwinHost.hermesServe.host}${
    lib.optionalString (httpsPort != 443) ":${toString httpsPort}"
  }";
in
{
  imports = [
    ./homebrew.nix
    ./preferences.nix
    ./remote-login
    ../../../modules/tailscale/nix-darwin.nix
  ];

  modules.tailscale = {
    enable = true;
    incoming.enable = true;
    ssh.enable = false;
    serve = lib.mkIf serveHermes {
      enable = true;
      target = "http://127.0.0.1:${toString hermes.backend.port}";
    };
  };

  home-manager.users.${darwinHost.username} = lib.mkIf serveHermes {
    services.hermes-agent.settings.dashboard.public_url = hermesUrl;
    modules.hermes.protonPassReferences = {
      HERMES_DASHBOARD_BASIC_AUTH_USERNAME = "${darwinHost.hermesServe.loginRef}/Username";
      HERMES_DASHBOARD_BASIC_AUTH_PASSWORD = "${darwinHost.hermesServe.loginRef}/Password";
    };
  };

  # nix-darwin loads system jobs before Home Manager updates the Dashboard.
  launchd.daemons.tailscale-serve = lib.mkIf (serveHermes && config.modules.tailscale.serve.enable) {
    serviceConfig.ProgramArguments = lib.mkBefore [
      (toString (
        pkgs.writeShellScript "serve-authenticated-hermes" ''
          set -o pipefail
          if ! ${lib.getExe pkgs.curl} --fail --silent --max-time 3 --noproxy '*' \
              --header ${lib.escapeShellArg "Host: ${lib.removePrefix "https://" hermesUrl}"} \
              ${lib.escapeShellArg "${config.modules.tailscale.serve.target}/api/status"} \
              | ${lib.getExe pkgs.jq} -e \
                '.auth_required == true and (.auth_providers | index("basic") != null)' >/dev/null; then
            echo "Tailscale Serve is waiting for the password-protected Hermes Dashboard." >&2
            exit 1
          fi
          exec "$@"
        ''
      ))
    ];
  };

  assertions = lib.optional serveHermes {
    assertion = hermes.backend.host == "127.0.0.1" && hermes.settings.dashboard.public_url == hermesUrl;
    message = "Hermes behind Tailscale Serve must use the loopback bind and the configured tailnet URL.";
  };

  nix.package = pkgs.lixPackageSets.stable.lix;
  nix.settings = {
    experimental-features = [
      "nix-command"
      "flakes"
    ];
    trusted-users = [ darwinHost.username ];
  };

  # Set Git commit hash for darwin-version.
  system.configurationRevision = configurationRevision;

  system.primaryUser = darwinHost.username;

  # Used for backwards compatibility, please read the changelog before changing.
  # $ darwin-rebuild changelog
  system.stateVersion = 6;

  # The platform the configuration will be used on.
  nixpkgs.hostPlatform = darwinHost.system;

  users.users.${darwinHost.username}.home = darwinHost.homeDirectory;
}
