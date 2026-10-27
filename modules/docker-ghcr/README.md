# GHCR authentication through GitHub CLI

English | [简体中文](README.zh-CN.md)

This module uses `gh` credentials to pull private images directly from GHCR.
Home Manager installs `docker-credential-ghcr` and declares
`credHelpers."ghcr.io" = "ghcr"` in `~/.docker/config.json`. Docker and Compose
remain host-provided. Enable the integration per host in the Linux inventory:

```nix
dockerGhcr = {
  enable = true;
  githubUser = "example-user";
};
```

The helper reads the account selected by `dockerGhcr.githubUser` in
[the Linux inventory](../../hosts/linux.nix), even when another account is active
in `gh`. Tokens stay in `gh`'s runtime credential storage; they are neither
copied into Docker configuration nor included in the Nix store. See the
[module options](../../docs/configuration.md#modulesdocker-ghcrenable).

Additional Docker client settings belong in `programs.docker-cli.settings`.

## Authenticate

After completing the repository's [Linux setup](../../docs/linux.md#first-activation),
authenticate once as the managed Linux user. Replace `example-user` with the
configured GitHub account. If GitHub access requires the managed proxy, prefix
the `gh` login or refresh command with `with-proxy`.

```sh
github_user=example-user
gh auth login --hostname github.com --web --scopes read:packages
gh auth status --hostname github.com
```

Complete the device authorization in a browser, signing in as the configured
account. It must have read access to the packages you want to pull. Later shells
and image pulls reuse this saved login. With an existing login, set `github_user`
as above and use these commands instead of logging in again:

```sh
gh auth switch --hostname github.com --user "$github_user"
gh auth refresh --hostname github.com --scopes read:packages
```

Run from the directory containing your Compose file:

```sh
docker compose pull
```

Image downloads use the Docker daemon's networking;
the helper does not configure its proxy.

## Credential lifecycle

Use `gh` for login, reauthorization, and logout; do not run `docker login` or
`docker logout` for GHCR. The helper rejects `store` and `erase`, and Home
Manager owns the read-only Docker configuration. Set `github_user` again if
using a new shell. To remove the account:

```sh
gh auth logout --hostname github.com --user "$github_user"
```

A missing token produces a login instruction. If pulling still returns
`denied`, check the account, `read:packages` scope, package Read permissions,
and any organization SSO requirements. Run Compose as the same managed Linux
account that authenticated with `gh`, without sudo.
Do not run the helper's `get` action manually: its output contains the token.

Protocol checks use a fake `gh` and never access real credentials:

```sh
nix build --no-link .#checks.x86_64-linux.docker-credential-ghcr
```
