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
  inherit (darwinHost) hermesDashboard;
  serveHermes = darwinHost ? hermesDashboard;
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
      inherit (hermesDashboard) httpsPort;
      enable = true;
      target = "http://127.0.0.1:${toString hermes.backend.port}";
    };
  };

  home-manager.users.${darwinHost.username} = lib.mkIf serveHermes {
    services.hermes-agent.settings.dashboard.public_url = hermesDashboard.url;
  };

  # nix-darwin loads system jobs before Home Manager updates the Dashboard.
  launchd.daemons.tailscale-serve = lib.mkIf (serveHermes && config.modules.tailscale.serve.enable) {
    serviceConfig.ProgramArguments = lib.mkBefore [
      (toString (
        import ../../../modules/hermes/serve-guard.nix {
          inherit lib pkgs;
          inherit (hermesDashboard) url;
          inherit (config.modules.tailscale.serve) target;
        }
      ))
    ];
  };

  assertions = lib.optional serveHermes {
    assertion =
      hermes.backend.host == "127.0.0.1"
      && hermes.backend.port != hermesDashboard.httpsPort
      && hermes.settings.dashboard.public_url == hermesDashboard.url;
    message = "Hermes Serve requires the configured tailnet URL and a separate loopback port.";
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
