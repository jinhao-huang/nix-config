{
  lib,
  local ? { },
}:
let
  piStartupDefaultsType = import ../modules/pi/startup-defaults-type.nix { inherit lib; };
  sshKeys = import ../modules/ssh/public-keys;
  inventories = {
    darwin = import ./darwin.nix { inherit sshKeys; };
    linux = import ./linux.nix { inherit sshKeys; };
  };
  hostNames = lib.concatMap builtins.attrNames (builtins.attrValues inventories);
  unknownHosts = lib.subtractLists hostNames (builtins.attrNames local);
  overrides =
    if !builtins.isAttrs local then
      throw "host-local must contain an attribute set keyed by host name."
    else if unknownHosts != [ ] then
      throw "Unknown hosts in host-local: ${lib.concatStringsSep ", " unknownHosts}"
    else
      lib.mapAttrs (
        name: host:
        if !builtins.isAttrs host then
          throw "host-local.${name} must be an attribute set containing only pi and hermes."
        else if lib.subtractLists [ "pi" "hermes" ] (builtins.attrNames host) != [ ] then
          throw "host-local.${name} may only override pi defaults and Hermes settings."
        else if !(builtins.isAttrs (host.pi or { }) && builtins.isAttrs (host.hermes or { })) then
          throw "host-local.${name}.pi and .hermes must be attribute sets."
        else if host ? hermes && !(builtins.hasAttr name inventories.linux) then
          throw "host-local.${name}.hermes requires a Linux host."
        else
          host
      ) local;
  merged = lib.mapAttrs (
    platform: inventory:
    lib.mapAttrs (
      name: host:
      host
      // {
        pi =
          (lib.evalModules {
            modules = [
              {
                _file = "Pi defaults for host ${name}";
                options.defaults = lib.mkOption {
                  type = piStartupDefaultsType;
                };
                # Replace the model pair together; absent fields inherit.
                config.defaults = (host.pi or { }) // (overrides.${name}.pi or { });
              }
            ];
          }).config.defaults;
      }
      // lib.optionalAttrs (platform == "linux") {
        hermes = lib.recursiveUpdate (host.hermes or { }) (overrides.${name}.hermes or { });
      }
    ) inventory
  ) inventories;
in
# Validate every entry, including overrides for a different build target.
builtins.deepSeq overrides (builtins.deepSeq merged merged)
