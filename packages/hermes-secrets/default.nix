{
  lib,
  writeShellApplication,
  writeText,
  python3,
  protonPass,
  openssh,
  linuxHosts,
}:
let
  targets =
    lib.mapAttrs
      (name: host: {
        destination = "${host.username}@${name}";
        path = host.hermesCredentialFile;
        references = writeText "hermes-${name}.env.refs" (
          lib.concatLines (lib.mapAttrsToList (key: ref: "${key}=${ref}") host.hermesProtonPass)
        );
        keys = builtins.attrNames host.hermesProtonPass;
      })
      (
        lib.filterAttrs (
          _: host:
          host ? hermesProtonPass
          && host ? hermesCredentialFile
          && lib.elem host.hermesCredentialFile (host.hermes.environmentFiles or [ ])
        ) linuxHosts
      );
  inventory = writeText "hermes-secret-targets.json" (builtins.toJSON targets);
in
writeShellApplication {
  name = "hermes-secrets";
  text = ''
    exec ${lib.getExe python3} ${./publish.py} ${inventory} \
      ${lib.getExe' protonPass "pass-cli"} ${lib.getExe' openssh "ssh"} "$@"
  '';
}
