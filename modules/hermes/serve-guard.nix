{
  lib,
  pkgs,
  url,
  target,
}:
pkgs.writeShellScript "serve-authenticated-hermes" ''
  set -o pipefail
  if ! ${lib.getExe pkgs.curl} --fail --silent --max-time 3 --noproxy '*' \
      --header ${lib.escapeShellArg "Host: ${lib.removePrefix "https://" url}"} \
      ${lib.escapeShellArg "${target}/api/status"} \
      | ${lib.getExe pkgs.jq} -e \
        '.auth_required == true and (.auth_providers | index("basic") != null)' >/dev/null; then
    echo "Tailscale Serve is waiting for the password-protected Hermes Dashboard." >&2
    exit 1
  fi
  exec "$@"
''
