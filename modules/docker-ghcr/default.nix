{
  config,
  lib,
  pkgs,
  ...
}:
let
  cfg = config.modules.docker-ghcr;
  helper = pkgs.callPackage ../../packages/docker-credential-ghcr {
    gh = config.programs.gh.package;
    inherit (cfg) githubUser;
  };
in
{
  _class = "homeManager";

  options.modules.docker-ghcr = {
    enable = lib.mkEnableOption "Docker authentication to GHCR through GitHub CLI";
    githubUser = lib.mkOption {
      type = lib.types.strMatching "[A-Za-z0-9][A-Za-z0-9-]*";
      example = "example-user";
      description = ''
        GitHub account whose stored gh token is used for ghcr.io, independent
        of gh's active account. Log in with read:packages at runtime; tokens
        are never included in the generated Docker configuration.
      '';
    };
  };

  config = lib.mkIf cfg.enable {
    programs.gh.enable = true;
    programs.docker-cli = {
      enable = true;
      configDir = ".docker";
      settings.credHelpers."ghcr.io" = "ghcr";
    };
    home.packages = [ helper ];
  };
}
