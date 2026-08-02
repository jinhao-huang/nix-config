# Repository Guidelines

## Project Structure & Module Organization

This repository is a Nix flake for personal macOS and Linux user environments.
`flake.nix` defines the flake inputs, package outputs, the `mac` nix-darwin
configuration, and the `linux-deployment` Home Manager configuration.
Keep top-level files focused on composition: `home.nix` wires user-level Home
Manager modules together, while `deployment.nix` defines the Linux deployment
profile.

Group cohesive features under `modules/<name>`. When a directory is imported as
a module, expose `default.nix` as its public entry point. Split larger
implementations into focused sibling modules and compose them with `imports`, as
done by `modules/darwin/default.nix`, `homebrew.nix`, and `mas-apps.nix`. Keep
related data beside its owning module, such as `modules/ssh/inventory.nix` and
`modules/starship/plain-text-symbols.toml`. Custom package derivations live in
`packages/<name>/default.nix`.

Keep nix-darwin-only settings in `modules/darwin` and user-level settings in
Home Manager modules. Use `home-manager.sharedModules` only for policy that must
apply to every configured Home Manager user; otherwise import the user module
explicitly from the relevant profile.

## Build, Test, and Development Commands

- `nix flake check --no-build`: evaluate standard flake outputs without building
  checks; use it as a fast structural check.
- `nix build --no-link .#darwinConfigurations.mac.system`: build the complete
  macOS system closure without creating a `result` symlink.
- `darwin-rebuild build --flake .#mac`: build the macOS system configuration
  without activating it; this is an equivalent host-oriented validation path.
- `sudo darwin-rebuild switch --flake .#mac`: build and activate the macOS
  configuration.
- `nix build .#mise` or `nix build .#proton-pass-cli`: build an exported custom
  package.
- `nix flake update`: update all locked inputs in `flake.lock`; use
  `nix flake update <input-name>` for targeted updates.

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
integrated Home Manager changes must also pass
`nix build --no-link .#darwinConfigurations.mac.system` or
`darwin-rebuild build --flake .#mac` before switching. For package changes,
build the affected package directly and verify hashes, supported platforms, and
`meta.mainProgram` when applicable. Use
`nix flake check --all-systems --no-build` when changing cross-platform package
outputs. Register new files with Git before running flake commands because Git
flakes ignore untracked paths.

## Commit & Pull Request Guidelines

Git history uses Conventional Commits such as `feat(ai-agents): ...`,
`chore(deps): ...`, and `docs(ai-agents): ...`. Keep commits scoped and mention
the touched module or package when useful. Pull requests should summarize the
configuration impact, list validation commands run, call out lockfile updates,
and include screenshots only for editor or UI configuration changes where visual
behavior matters.
