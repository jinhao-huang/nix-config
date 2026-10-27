# GitHub CLI, SSH, and signing

English | [简体中文](README.zh-CN.md)

Keep **SSH** as the Git protocol when using this repository's existing SSH
workflow. Git transport, commit signing, and GHCR authentication use separate
settings and can use different credentials.

## Repository policy

The [shared GitHub CLI module](default.nix) declares the same defaults on macOS
and Linux:

```nix
programs.gh = {
  settings.git_protocol = "ssh";
  gitCredentialHelper.enable = false;
};
```

| Operation | Configuration and credential |
| --- | --- |
| Git fetch, pull, and push | The repository's remote URL selects SSH or HTTPS. SSH uses an authentication key through OpenSSH and its agent configuration. `gh` prefers SSH for commands such as `gh repo clone`; it does not rewrite existing remotes. |
| Commit signing | The [Git module](../git/default.nix) enables SSH signatures by default and selects a public signing key with `key::`. The matching private key must be available through an agent. Signing works with either SSH or HTTPS remotes. |
| GitHub API and GHCR | `gh` uses its login token. The [Docker GHCR helper](../docker-ghcr/README.md) reads that token for the configured account; SSH keys and agent forwarding are unnecessary for image pulls. |

`gitCredentialHelper.enable = false` disables Home Manager's configuration of
`gh` as a **Git HTTPS** credential helper. It does not disable the **Docker**
credential helper or prevent `gh` login.

## SSH and HTTPS tradeoffs

| Choice | Benefits | Requirements |
| --- | --- | --- |
| SSH | Reuses the existing SSH keys and agent workflow; Git authentication does not depend on the `gh` token. | An agent or local authentication key must be available on the machine running Git. SSH routing may need separate configuration. |
| HTTPS with `gh` | Git can reuse the `gh` login; HTTPS usually fits HTTP proxies more easily. | Change the declarations in the shared GitHub CLI module to enable `programs.gh.gitCredentialHelper.enable` and set `programs.gh.settings.git_protocol = "https"`, then use HTTPS remotes. SSH signing still needs its signing agent. |

Both support encrypted connections. Choose based on the available credentials
and network access. For this repository's existing agent setup, retain SSH.
Changing only the login prompt to HTTPS does not change existing SSH remotes.
See GitHub's [remote URL documentation](https://docs.github.com/en/get-started/git-basics/about-remote-repositories).

On Linux, `with-proxy` handles `gh`'s HTTP requests, not OpenSSH transport.
Selecting SSH as the Git preference still leaves `gh` login and API requests
using HTTPS; Git over SSH needs its own working network route.

## Existing keys and agents

The [Darwin profile](../../profiles/home/darwin.nix) uses the
[Proton Pass agent](../proton-pass/default.nix) for Git signing and SSH inventory
identities. The [Linux SSH procedure](../../docs/linux.md#shell-and-ssh)
uses an explicitly forwarded agent for signing; the Linux profile does not start
the Proton Pass agent. Keys available on the Mac are not automatically available
on Linux. The shared SSH module disables agent forwarding by default.

A key in `authorizedKeyFiles` allows incoming login to the managed account; it
does not grant outgoing GitHub access or select a Git signing key. GitHub also
distinguishes **Authentication keys** from **Signing keys**. A key registered only
for signing cannot authenticate Git operations. To use the same public key for
both, register it in both roles; separate keys are also supported. See GitHub's
[key registration instructions](https://docs.github.com/en/authentication/connecting-to-github-with-ssh/adding-a-new-ssh-key-to-your-github-account).

When logging in, use `--git-protocol ssh --skip-ssh-key` to retain this policy
and skip key generation and upload prompts. Existing keys remain managed by the
agent. These flags do not replace browser authorization or the token required
for GHCR. Follow the existing [macOS login](../../docs/darwin.md#github-cli) or
[GHCR login](../docker-ghcr/README.md#authenticate) procedure once; an existing
login only needs additional scopes when required.
See the [login flags](https://cli.github.com/manual/gh_auth_login).

## Check or correct a previous protocol choice

Run these checks on the machine where Git runs, from an existing checkout:

```sh
gh config get git_protocol --host github.com
git remote -v
ssh -T git@github.com
```

The [SSH check](https://docs.github.com/en/authentication/connecting-to-github-with-ssh/testing-your-ssh-connection)
reports the authenticated GitHub username and exits with status 1 even on
success because GitHub does not provide shell access. These Git checks are
optional for GHCR; a missing SSH agent does not block token authentication.

Home Manager owns `~/.config/gh/config.yml`; `gh` owns runtime account settings
in `~/.config/gh/hosts.yml` and its credential store. A previous login can leave
a host-specific protocol that overrides the declared default. If the first
command reports `https`, restore SSH for that host without logging in again:

```sh
gh config set git_protocol ssh --host github.com
```

Do not run `gh auth setup-git` for this SSH workflow. Make persistent Git
credential-helper changes in Nix, where Git configuration is managed.
