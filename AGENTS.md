# Repository Guidelines

## Project Structure & Module Organization

This repository is a Nix flake for personal macOS and Linux user environments.
`flake.nix` defines the flake inputs, package outputs, the `laptop` and `desktop`
nix-darwin configurations, and standalone Linux Home Manager configurations
from `hosts/linux.nix`.
Keep `flake.nix` focused on composition and package-source selection. User-level
Home Manager profiles live in `profiles/home`: `common.nix` owns shared CLI
policy, while `darwin.nix` and `linux.nix` own their platform-specific policy.
Darwin system policy lives in `profiles/system/darwin`: `default.nix` composes
shared settings, preferences, Homebrew application choices, and Remote Login;
`laptop.nix` and `desktop.nix` own role-specific application choices.
Keep Linux account paths and architectures in `hosts/linux.nix`; this repository
manages Linux user environments rather than the host operating system.

Keep README focused on user-facing setup, daily use, and troubleshooting.
Keep additions very short and match the brevity of nearby sections. Include only
essential commands and critical caveats; point to configuration instead of
listing its options. Put detailed rationale and analysis in task reports.
Document architecture and contributor validation in agent or developer guidance.

Group cohesive features under `modules/<name>`. When a directory is imported as
a module, expose `default.nix` as its public entry point. Compose configuration
choices in profiles and keep feature implementations in modules. Keep
related data beside its owning module, such as `modules/ssh/inventory.nix` and
`modules/starship/plain-text-symbols.toml`. Custom package derivations live in
`packages/<name>/default.nix`.

Keep reusable nix-darwin feature implementations in `modules/darwin` and select
their behavior from the system profiles. Keep user-level settings in Home Manager
profiles and modules. Use `home-manager.sharedModules` only for policy that must
apply to every configured Home Manager user; otherwise import the user module
explicitly from the relevant profile.

Use native `programs.*.package` options when available. Keep package-source
selection in flake composition rather than passing package sets through
`extraSpecialArgs`. Darwin owns the system Lix installation; standalone Linux
Home Manager selects activation and shell tools without managing the host daemon.

## Build, Test, and Development Commands

- `nix flake check --no-build`: evaluate standard flake outputs without building
  checks; use it as a fast structural check.
- `nix flake check --all-systems --no-build`: also evaluate Linux Home Manager
  activation packages registered as checks from the host inventory.
- `nix build --no-link .#darwinConfigurations.laptop.system
  .#darwinConfigurations.desktop.system`: build both complete macOS system
  closures without creating a `result` symlink; use this for shared Darwin
  changes.
- `darwin-rebuild build --flake .#laptop` or `darwin-rebuild build --flake
  .#desktop`: build one role without activating it; use the affected role for
  role-specific changes.
- `sudo darwin-rebuild switch --flake .#laptop` or `sudo darwin-rebuild switch
  --flake .#desktop`: build and activate the explicitly selected role.
- `nix build .#mise` or `nix build .#proton-pass-cli`: build an exported
  package.
- `nix build --no-link .#homeConfigurations.iscas-r750xa.activationPackage`:
  build the Linux user environment on an x86_64 Linux builder without activation.
- `home-manager switch --flake .#iscas-r750xa`: activate the Linux profile as
  its declared user, without sudo. See the README for first-time setup.
- `nix flake update`: update all locked inputs in `flake.lock`; use
  `nix flake update <input-name>` for targeted updates.
- Homebrew tap inputs (`homebrew-cask`, `homebrew-core`, `homebrew-steipete`,
  `homebrew-jinhao-huang`) must always be updated together with
  `nix-homebrew` in the same change, because its `brew-src` input pins the
  Homebrew version. Updating taps alone can land cask DSL that the pinned
  brew cannot parse and abort activation; see the unlock runbook in
  `profiles/system/darwin/homebrew.nix`.

## Coding Style & Naming Conventions

Format Nix files with `nixfmt`. Use two-space indentation, attribute sets over
ad hoc string concatenation where practical, and short comments only when they
explain non-obvious configuration decisions. Name modules and packages with
lowercase kebab-case directories, for example `modules/ai-agents` or
`packages/proton-pass-cli`.

Prefer qualified `lib.*` calls over broad `with lib;` scopes. Declare reusable
module interfaces with typed options, use `lib.mkEnableOption` for optional
features, and keep option declarations with the module that owns the behavior.
Use normal module options for values shared between modules. Reserve
`specialArgs` and `extraSpecialArgs` for flake inputs, host inventory, or values
needed during import resolution rather than general configuration plumbing.

Before using `home.file`, `xdg.configFile`, or custom activation code, check
whether Home Manager or nix-darwin provides a native module option for the
software. Prefer native module options whenever they can express the desired
configuration. Use raw generated files only when no suitable native option
exists, and document why the exception is necessary.

Prefer declarative Home Manager or nix-darwin options over activation scripts
for files, symlinks, packages, and services. Use activation scripts only for
runtime state validation, external secret synchronization, or migration that
cannot be modeled declaratively. Keep such scripts idempotent, preserve usable
state on failure, quote generated shell arguments with `lib.escapeShellArg`, and
use Nix store paths for required tools. Home Manager activation scripts must
respect `DRY_RUN_CMD` when they perform external side effects.

## Testing Guidelines

There is no separate unit test suite. Run `nixfmt --check` on every touched Nix
file and use `nix flake check --no-build` as baseline validation. Because
`nix flake check` does not build the nix-darwin system closure, Darwin and
integrated Home Manager changes must also pass the applicable complete-system
build above before switching: build both roles for shared changes and the
affected role for role-specific changes. For package changes, build the affected
package directly and verify hashes, supported platforms, and `meta.mainProgram`
when applicable. Use
`nix flake check --all-systems --no-build` when changing cross-platform package
outputs. Register new files with Git before running flake commands because Git
flakes ignore untracked paths.
Standalone Linux activation packages are registered under
`checks.<system>.<name>-home`; use `nix flake check --all-systems --no-build` to
evaluate them from a different platform. For Linux changes, also explicitly
evaluate and build the affected `homeConfigurations.<name>.activationPackage`.
Use a Linux builder for the complete closure.

## Commit & Pull Request Guidelines

Git history uses Conventional Commits such as `feat(ai-agents): ...`,
`chore(deps): ...`, and `docs(ai-agents): ...`. Keep commits scoped and mention
the touched module or package when useful. Pull requests should summarize the
configuration impact, list validation commands run, call out lockfile updates,
and include screenshots only for editor or UI configuration changes where visual
behavior matters.
