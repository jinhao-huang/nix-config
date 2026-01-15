{ lib, config, ... }:

{
  options.modules = {
    repoRelativePath = lib.mkOption {
      type = lib.types.str;
      description = "Path to the repository relative to the home directory (e.g., 'nix-config').";
    };

    repoPath = lib.mkOption {
      type = lib.types.path;
      readOnly = true;
      description = "The absolute path to the configuration repository (calculated from repoRelativePath).";
      default = "${config.home.homeDirectory}/${config.modules.repoRelativePath}";
    };
  };
}
