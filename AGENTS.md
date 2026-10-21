# Repository guidelines

This flake manages personal macOS systems with nix-darwin and Home Manager,
and Linux user environments with standalone Home Manager.

## Read by task

- Before changing flake composition, host inventory, profiles, or modules, read
  [development guidance](docs/development.md) for ownership and module conventions.
- Before validating a change, follow the applicable
  [validation rules](docs/development.md#validation). Evaluation alone does not
  build a Darwin system closure.
- For setup, activation, and input updates, start at [README.md](README.md).
  For host fields and service options, use the generated
  [configuration reference](docs/configuration.md).

## Implementation rules

Compose choices in profiles, host data in `hosts`, reusable features in
`modules`, and package-source selection in `flake.nix`. Use native
`programs.*.package` options rather than passing package sets through
`extraSpecialArgs`. Local inventory may override only Pi startup defaults;
keep its schema and settings generation in `modules/pi`.

Format touched Nix files with `nixfmt`, using two-space indentation and qualified
`lib.*` calls. Prefer attribute sets to ad hoc string concatenation, and comment
only non-obvious decisions. Use lowercase kebab-case directories. Keep reusable
options typed and owned by their module; prefer `lib.mkEnableOption` for optional features.
Share values through module options; reserve `specialArgs` and
`extraSpecialArgs` for inputs, inventory, and import resolution.

Check native Home Manager or nix-darwin options before generating raw files or
activation scripts. Document why an exception is needed. Activation scripts are
for runtime validation, external secret synchronization, or migration that cannot
be modeled declaratively. Make them idempotent, preserve usable state on failure,
quote arguments with `lib.escapeShellArg`, and use Nix store paths for tools.
Home Manager external side effects must respect `DRY_RUN_CMD`.

## Documentation and delivery

Keep README a short entry point for setup and daily commands. Put platform
procedures in `docs/darwin.md` or `docs/linux.md`, architecture and contributor
validation in `docs/development.md`, and feature-specific maintenance beside
its module. Keep each fact in one place and link to it elsewhere. Treat bundled
skills and agent prompts as deployed project inputs, not general project docs.

Use Conventional Commits, scoped to the affected module or package when useful.
PR descriptions explain configuration impact, validation, and lockfile updates;
include screenshots only when editor or UI behavior matters.
