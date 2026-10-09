{
  configurationRevision,
  darwinHost,
  pkgs,
  ...
}:
{
  imports = [
    ./homebrew.nix
    ./preferences.nix
    ./remote-login
    ../../../modules/darwin/tailscale-ingress
  ];

  modules.tailscale-ingress.enable = true;

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
