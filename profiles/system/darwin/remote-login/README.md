# macOS Remote Login

English | [简体中文](README.zh-CN.md)

Enables Apple's built-in SSH server for both Darwin profiles. See
[default.nix](default.nix) for the login policy and
[host inventory](../../../../hosts/darwin.nix) for authorized client keys.
User-managed `~/.ssh/authorized_keys` is ignored.

## Boundaries

- macOS's Remote Login user list is an additional access check. Full disk access
  is a separate permission.
- launchd owns TCP 22; `Port` and `ListenAddress` in `sshd_config` do not change
  the listener. This profile does not restrict access to the tailnet.
- Both profiles' [Tailscale SSH](../../../../modules/tailscale/README.md)
  uses independent authorization; this profile's login policy does not apply to it.
- On macOS 26+, [FileVault SSH unlock](https://github.com/apple-oss-distributions/OpenSSH/blob/main/apple_ssh_and_filevault.7)
  uses password authentication before the normal SSH configuration is available.
  Test reboot and unlock separately; normal launchd state alone does not prove
  the Preboot SSH state.
