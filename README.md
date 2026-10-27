# Personal Nix environments

English | [简体中文](README.zh-CN.md)

Nix flake for personal macOS workstations and Linux development-server user
environments. macOS uses nix-darwin with Home Manager; Linux uses standalone
Home Manager and leaves the host OS and Nix daemon to its administrator.

## Setup and documentation

Have Nix or Lix and Git available, then check out the repository at
`~/nix-config`. The profiles use that location for live AI skill links; if you
choose another location, update `modules.ai-agents.repoRelativePath` in the home
profile before activation. Follow one platform guide through its preparation,
first activation, and authentication steps.

| Task | Guide |
| --- | --- |
| Set up a Mac; authenticate GitHub CLI and Proton Pass | [macOS](docs/darwin.md) |
| Set up a Linux account; use SSH and user services | [Linux](docs/linux.md) |
| Change host fields, Pi defaults, or service options | [Configuration reference](docs/configuration.md) |
| Change the architecture, modules, or validation | [Development](docs/development.md) |
| Look up profile terminology | [Glossary](GLOSSARY.md) |
| Maintain English and Chinese documentation | [Documentation synchronization](docs/development.md#documentation-sync) |

## Build and switch

These are routine rebuild commands for an already configured machine; the
platform guide owns first activation. Run as the regular user from the checkout.
Choose `laptop` or `desktop` for macOS, or a host from
[hosts/linux.nix](hosts/linux.nix) for Linux:

```sh
deploy_host=laptop # Or desktop; use your Linux inventory key on Linux.
nix run .#deploy -- build "$deploy_host"
nix run .#deploy -- switch "$deploy_host"
```

Use `build` when you want to check a build without activating it. `switch` builds and activates it,
invoking `sudo -H` on macOS and running without sudo on Linux. Both commands
create and load Git-ignored `hosts/inventory.local.nix`; it may override
[Pi startup defaults](docs/configuration.md#pi-startup-defaults) and
[Hermes settings](modules/hermes/README.md#per-host-configuration). Keep secrets
out of Nix values, including ignored overrides: they enter the Nix store.

## Update inputs

```sh
nix flake update                # All inputs
nix flake update nixpkgs        # One input, for example
```

Always update `nix-homebrew` and all four `homebrew-*` tap inputs together:

```sh
nix flake update nix-homebrew homebrew-core homebrew-cask homebrew-steipete homebrew-jinhao-huang
```

Its `brew-src` pins the Homebrew version; newer taps can require a newer cask
DSL. See [the Homebrew activation runbook](profiles/system/darwin/homebrew.nix)
if an existing mismatch blocks activation. Validate changes using the
[development checks](docs/development.md#validation), then build and switch.
