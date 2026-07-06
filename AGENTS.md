# Repository Guidelines

## Project Structure & Module Organization

This repository is a Nix flake for personal macOS and Linux user environments.
`flake.nix` defines the flake inputs, package outputs, the `mac` nix-darwin
configuration, and the `linux-deployment` Home Manager configuration.
`home.nix` wires user-level Home Manager modules together. Reusable modules live
under `modules/<name>/default.nix`, with related assets beside them, such as
`modules/zed/settings.json` and `modules/starship/plain-text-symbols.toml`.
Custom package derivations live in `packages/<name>/default.nix`. Keep
machine-wide Darwin settings in `modules/darwin`, deployment-specific Linux
settings in `deployment.nix`, and shell snippets in files such as `zshrc.conf`.

## Build, Test, and Development Commands

- `nix flake check`: evaluate flake outputs and catch syntax or evaluation
  errors before submitting changes.
- `darwin-rebuild build --flake .#mac`: build the macOS system configuration
  without activating it.
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
`packages/proton-pass-cli`. Prefer one focused `default.nix` per module or
package.

## Testing Guidelines

There is no separate unit test suite. Treat `nix flake check` and targeted
builds as the baseline validation. For Darwin changes, run
`darwin-rebuild build --flake .#mac` before switching. For package changes,
build the affected package directly and verify hashes, platforms, and
`meta.mainProgram` when applicable.

## Commit & Pull Request Guidelines

Git history uses Conventional Commits such as `feat(ai-agents): ...`,
`chore(deps): ...`, and `docs(ai-agents): ...`. Keep commits scoped and mention
the touched module or package when useful. Pull requests should summarize the
configuration impact, list validation commands run, call out lockfile updates,
and include screenshots only for editor or UI configuration changes where visual
behavior matters.
