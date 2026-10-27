# Development

English | [简体中文](development.zh-CN.md)

## Architecture and ownership

The flake composes host data, profiles, and feature modules into Darwin systems
and standalone Linux home environments. See [GLOSSARY.md](../GLOSSARY.md) for
profile terminology.

| Location | Responsibility |
| --- | --- |
| [flake.nix](../flake.nix) | Inputs, package sources, configuration composition, exported packages, and checks. |
| [hosts](../hosts) | Host data, including machine-specific application choices; `default.nix` validates and merges optional `host-local` Pi and Hermes overrides. |
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
| Hermes runtime or activation | `nix build --no-link .#checks.aarch64-darwin.hermes-runtime` (substitute the native system on Linux), plus the platform checks above. |
| Bundled skills or source metadata | `nix build --no-link .#checks.aarch64-darwin.ai-agent-skills` (substitute the native system on Linux). |
| Configuration reference | Regenerate as below, then run `nix build --no-link .#checks.aarch64-darwin.configuration-reference` (substitute the native system on Linux). |
| GHCR credential helper | `nix build --no-link .#checks.aarch64-darwin.docker-credential-ghcr` (substitute the native system on Linux), plus Linux home-profile checks when wiring changes. |

Linux activation packages are registered as `checks.<system>.<name>-home`.
For a Linux host, replace `example-host` with its inventory key:

```sh
deploy_host=example-host
nix eval --raw ".#homeConfigurations.${deploy_host}.activationPackage.drvPath"
nix build --no-link ".#homeConfigurations.${deploy_host}.activationPackage"
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

## Documentation sync

Public guides may use role names such as `laptop` and `desktop` and describe
their configuration. Use placeholders or home-relative paths for names,
accounts, network addresses, and deployment paths that identify real machines.
Keep those deployment details in host configuration. Preserve real option and
input names in commands.

When anonymizing a home directory, preserve the useful path beneath it, such as
`.config/hermes/secrets.env`. Keep shared setup and activation procedures in
the platform guides; feature guides link to that flow and document their own
configuration and runtime steps.

Maintain English documentation and its Simplified Chinese companion in the same
change. A change to behavior, prerequisites, commands, host fields, option names,
types, defaults, examples, validation, or maintenance procedures triggers a review
of both languages. A correction originating in either language must reach the
other when it changes meaning. Code and Nix declarations determine behavior;
resolve disagreements against the implementation before updating both documents.

Use the same directory and basename with the suffix `.zh-CN.md`. Each document
links to its language counterpart, and Chinese navigation links to Chinese
guides where available. Keep commands, identifiers, paths, literal values, and
code examples consistent. Translate explanatory prose; preserve required code
and agent-input language conventions. The following table defines coverage:

| English document | Chinese companion |
| --- | --- |
| [README.md](../README.md) | [README.zh-CN.md](../README.zh-CN.md) |
| [GLOSSARY.md](../GLOSSARY.md) | [GLOSSARY.zh-CN.md](../GLOSSARY.zh-CN.md) |
| [docs/darwin.md](darwin.md) | [docs/darwin.zh-CN.md](darwin.zh-CN.md) |
| [docs/linux.md](linux.md) | [docs/linux.zh-CN.md](linux.zh-CN.md) |
| [docs/development.md](development.md) | [docs/development.zh-CN.md](development.zh-CN.md) |
| [docs/configuration.md](configuration.md) | [docs/configuration.zh-CN.md](configuration.zh-CN.md) |
| [modules/ai-agents/README.md](../modules/ai-agents/README.md) | [modules/ai-agents/README.zh-CN.md](../modules/ai-agents/README.zh-CN.md) |
| [modules/hermes/README.md](../modules/hermes/README.md) | [modules/hermes/README.zh-CN.md](../modules/hermes/README.zh-CN.md) |
| [modules/docker-ghcr/README.md](../modules/docker-ghcr/README.md) | [modules/docker-ghcr/README.zh-CN.md](../modules/docker-ghcr/README.zh-CN.md) |
| [modules/gh/README.md](../modules/gh/README.md) | [modules/gh/README.zh-CN.md](../modules/gh/README.zh-CN.md) |
| [modules/starship/README.md](../modules/starship/README.md) | [modules/starship/README.zh-CN.md](../modules/starship/README.zh-CN.md) |
| [modules/tailscale/README.md](../modules/tailscale/README.md) | [modules/tailscale/README.zh-CN.md](../modules/tailscale/README.zh-CN.md) |
| [profiles/system/darwin/remote-login/README.md](../profiles/system/darwin/remote-login/README.md) | [profiles/system/darwin/remote-login/README.zh-CN.md](../profiles/system/darwin/remote-login/README.zh-CN.md) |

`docs/configuration.md` remains generated from
`docs/configuration-intro.md` and Nix option declarations. Edit those sources,
regenerate the English reference, then manually synchronize the complete Chinese
reference, including its introduction and every option entry. The Chinese
reference is maintained directly; the generator does not overwrite it. Preserve
option headings and their anchors, types, defaults, examples, and declaration
links. Add and remove option entries in both languages together. Generated
`options.json` remains machine-readable and untranslated.

When adding, moving, or deleting a project guide, update both language versions,
their inbound links, and this coverage table. Bundled third-party skill documents,
agent prompts, `AGENTS.md`, source records, and licenses remain deployment or
agent inputs under their existing language conventions; they do not require
translated companions.

Before delivering a documentation change:

1. Compare both versions against the implementation and each other, including
   conditions, limitations, and command effects.
2. Check relative links and heading anchors after renames or heading changes.
3. If reference sources changed, regenerate and run the configuration-reference
   check above; compare the option inventory, types, defaults, and code examples
   against the Chinese reference.
4. Review Chinese prose for clarity while preserving facts and uncertainty.
   Report which document pairs changed and what validation ran. For a behavior
   change requiring no documentation update, explain why in the delivery notes.
