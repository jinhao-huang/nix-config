# Development

## Architecture and ownership

The flake composes host data, profiles, and feature modules into Darwin systems
and standalone Linux home environments. See [GLOSSARY.md](../GLOSSARY.md) for
profile terminology.

| Location | Responsibility |
| --- | --- |
| [flake.nix](../flake.nix) | Inputs, package sources, configuration composition, exported packages, and checks. |
| [hosts](../hosts) | Host data, including machine-specific application choices; `default.nix` validates and merges optional `host-local` Pi and Linux Hermes overrides. |
| [profiles/home](../profiles/home) | Shared CLI policy in `common.nix`; platform-specific user choices in `darwin.nix` and `linux.nix`. |
| [profiles/system/darwin](../profiles/system/darwin) | Shared macOS settings, preferences, applications, and Remote Login; combines shared applications with each host's application list. |
| [modules](../modules) | Independently reusable features, their options, and supporting data. |
| [packages](../packages) | Custom derivations, including the deployment command and configuration-reference generator. |

Darwin integrates Home Manager and owns the system Lix installation. Linux
selects activation and shell tools; its OS and Nix daemon remain
administrator-owned. The Linux profile connects sing-box, the Harness backend
and cookie proxy, and Tailscale Serve through module options, with a check for
distinct loopback ports.

## Module conventions

Compose shared feature choices in the owning profile and keep machine-specific
application lists in host inventory. Keep profile-specific helpers
beside that profile and feature data beside its module, such as SSH inventory
or Starship symbols. Use `home-manager.sharedModules` only for policy that must
apply to every configured Home Manager user; otherwise import the module from
the relevant profile. Select system features from system profiles and user
features from home profiles.

A single-entry feature exposes `default.nix`. Features targeting multiple
evaluators expose `home-manager.nix` and `nix-darwin.nix`; profiles import the
matching entry. Declare `_class = "homeManager"` or `"darwin"` in evaluator entry
points and enforce platform restrictions with assertions. Keep shared options
and private implementations inside the feature directory. Custom derivations
use `packages/<name>/default.nix`.

## Agent guidance

[Global guidance](../modules/ai-agents/global-guidelines.md) and machine context
from the home profiles are deployed together. After editing either, rebuild and
switch, then start a new agent session. Skills are linked to their source
directories; edits to existing linked content are live. Changes to the set of
deployed skills require a rebuild and switch. See
[AI agent maintenance](../modules/ai-agents/README.md) for source records and
skill validation.

## Validation

Run from the repository root. Register new files with Git before flake commands;
Git flakes ignore untracked paths. For Nix changes, run `nixfmt --check` on every
touched Nix file. Use `nix flake check --no-build` as the baseline evaluation;
it does not build checks or complete Darwin closures.

| Change | Additional validation before switching |
| --- | --- |
| Shared Darwin or integrated Home Manager | `nix build --no-link .#darwinConfigurations.laptop.system .#darwinConfigurations.desktop.system` |
| One Darwin host | `darwin-rebuild build --flake .#laptop` (or `desktop`). |
| Linux home profile | `nix flake check --all-systems --no-build`, then explicitly evaluate and build `homeConfigurations.<name>.activationPackage` on a Linux builder. |
| Package | Build the affected exported package; verify hashes, supported platforms, and `meta.mainProgram` where applicable. Also evaluate all systems when package outputs change. |
| sing-box runtime or linger helper | `python3 modules/sing-box/tests.py` in addition to the relevant Linux checks. |
| Bundled skills or source metadata | `nix build --no-link .#checks.aarch64-darwin.ai-agent-skills` (substitute the native system on Linux). |
| Configuration reference | Regenerate as below, then run `nix build --no-link .#checks.aarch64-darwin.configuration-reference` (substitute the native system on Linux). |

Linux activation packages are registered as `checks.<system>.<name>-home`.
For the current server, explicit evaluation and build commands are:

```sh
nix eval --raw .#homeConfigurations.iscas-r750xa.activationPackage.drvPath
nix build --no-link .#homeConfigurations.iscas-r750xa.activationPackage
```

## Generated reference

Edit descriptions and examples in the owning Nix option declarations, and host
and Pi explanations in [configuration-intro.md](configuration-intro.md). Then run:

```sh
nix run .#update-configuration-reference
```

[configuration.md](configuration.md) is generated; edit its sources instead.
The `configuration-reference` package also exports machine-readable
`options.json`. Generation reads no secrets and activates no services.
