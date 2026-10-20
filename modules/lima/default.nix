{
  config,
  lib,
  pkgs,
  ...
}:
let
  cfg = config.modules.lima;
in
{
  _class = "homeManager";

  imports = [ ../ai-agents ];

  options.modules.lima = {
    enable = lib.mkEnableOption "Lima virtual machines and agent guidance";

    package = lib.mkPackageOption pkgs "lima" { };
  };

  config = lib.mkIf cfg.enable {
    assertions = [
      {
        assertion = pkgs.stdenv.isDarwin || pkgs.stdenv.isLinux;
        message = "Lima requires macOS or Linux.";
      }
    ];

    home.packages = [ cfg.package ];

    modules.ai-agents.environment = lib.mkAfter ''

      ## Linux VM Validation

      - Lima (`limactl`) is available on this machine for Linux VM validation. Use the repository's VM/test workflow when provided.
      - Give ad hoc instances a project-specific prefix and pass their names explicitly. Operate only on instances owned by the current task; keep VM definitions and lifecycle rules in the owning repository.
    '';
  };
}
