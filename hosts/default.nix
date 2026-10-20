{
  lib,
  local ? { },
}:
let
  piStartupDefaultsType = import ../modules/pi/startup-defaults-type.nix { inherit lib; };
  inventories = {
    darwin = import ./darwin.nix;
    linux = import ./linux.nix;
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
          throw "host-local.${name} must be an attribute set containing only pi."
        else if lib.subtractLists [ "pi" ] (builtins.attrNames host) != [ ] then
          throw "host-local.${name} may only override pi defaults."
        else if !builtins.isAttrs (host.pi or { }) then
          throw "host-local.${name}.pi must be an attribute set."
        else
          host.pi or { }
      ) local;
  merged = lib.mapAttrs (
    _: inventory:
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
                config.defaults = (host.pi or { }) // (overrides.${name} or { });
              }
            ];
          }).config.defaults;
      }
    ) inventory
  ) inventories;
in
# Validate every entry, including overrides for a different build target.
builtins.deepSeq overrides (builtins.deepSeq merged merged)
