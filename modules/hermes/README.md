# Hermes

English | [简体中文](README.zh-CN.md)

Hermes uses the official Home Manager module on Linux and macOS. Nix manages
the program, services, and default configuration. Authentication state, sessions,
memory, scheduled jobs, and locally created skills remain writable.

## Per-host configuration

Set `hermes` in [hosts/linux.nix](../../hosts/linux.nix) or
[hosts/darwin.nix](../../hosts/darwin.nix). Fields map to official
[`services.hermes-agent` options](https://hermes-agent.nousresearch.com/docs/getting-started/nix-setup#home-manager-module).
`iscas-r750xa` enables the messaging gateway; `laptop` and `desktop` disable both
Hermes and the gateway. `hermes.enable = true` installs the CLI and manages its
configuration. `hermes.gateway.enable = true` additionally runs a systemd user
service on Linux or a launchd agent on macOS. Leave the gateway disabled for
CLI/TUI use only. The optional web backend remains disabled by default.

[Shared policy](../../profiles/home/hermes.nix) disables update checks, automatic
borrowing of Codex/Claude logins (`auth.adopt_external_logins`), and on-demand
dependency installation (`security.allow_lazy_installs`). Declare dependencies
through `extraPackages`, `extraDependencyGroups`, or `extraPythonPackages` when
needed. Platform profiles own environment hints and proxy integration.

### Local overrides

Add host-specific values to Git-ignored `hosts/inventory.local.nix`. Hermes
attributes merge recursively; scalars and lists replace tracked values. Use the
[deployment command](../../README.md#build-and-switch) to load this file.
Replace the following model values to enable CLI/TUI use on a Mac:

```nix
{
  laptop.hermes = {
    enable = true;
    gateway.enable = false;
    settings.model = {
      provider = "custom";
      default = "private-model-id";
      base_url = "https://llm.example.internal/v1";
      api_mode = "chat_completions";
    };
    environmentFiles = [ "/Users/jinhaohuang/.config/hermes/secrets.env" ];
  };
}
```

Use `iscas-r750xa.hermes` for server overrides. Local validation requires both
`settings.model.provider` and `settings.model.default`. A custom endpoint also
needs the correct `base_url` and API protocol. For Telegram, supply
`environment.TELEGRAM_ALLOWED_USERS` as comma-separated numeric user IDs. To
receive proactive messages or cron results, also set
`environment.TELEGRAM_HOME_CHANNEL`.

Local Nix values enter the Nix store. Keep keys and tokens in private runtime
files. The tracked inventory supplies no model or allowed user IDs; prepare
them before switching an enabled host.

## Secrets and activation

The Linux host reads `/home/huangjh/.config/hermes/secrets.env`. Create the
user-owned file with mode `0600` or `0400` and its parent with mode `0700`:

```dotenv
OPENAI_API_KEY=replace-on-the-server
TELEGRAM_BOT_TOKEN=replace-on-the-server
```

Use the credential variable required by your model provider. A CLI-only Mac
does not need a Telegram token. Activation rejects missing model settings,
unreadable or non-private secret files, missing Telegram tokens, invalid user
IDs, and public Telegram access. Builds do not require runtime secrets. These
checks do not test external authentication.

Switch after changing settings or a secret file. Activation:

1. Validates inputs before the Home Manager write boundary and again before
   applying state.
2. Creates or repairs the Hermes state root and managed state subdirectories
   with mode `0700`. New state files use a private umask.
3. Replaces the complete `config.yaml` and atomically replaces `.env` with mode
   `0600`. Public values come first, followed by private files in order; later
   values win. Empty environment declarations produce an empty `.env`, removing
   previously installed values.
4. Restarts active systemd services or loaded launchd agents when configuration
   or environment changes, after native service setup. An unchanged activation
   does not request an extra restart. Failed restarts remain pending for the
   next switch.

The native service manager also handles package and unit changes. CLI-only use
has no background service to restart; open a new CLI session after switching.
Both native service managers start Hermes with umask `0077`.
Dry runs do not write state or restart services. State setup reuses upstream
document, auth-seeding, and plugin handling. Rendering and state preparation
use upstream `moduleCommon.nix`; verify that interface on input updates.
Regression checks run with:

```sh
nix build --no-link .#checks.aarch64-darwin.hermes-runtime
```

## Configuration ownership and isolation

Managed mode blocks ordinary setup, config mutation, update, and gateway
installation commands. Edit Nix and switch for persistent defaults. The marker
is an application convention, not a filesystem security boundary: the account
owner can still edit ordinary files, and a switch restores managed YAML and env
values.

Per-chat `/model` and `/reasoning` choices, `hermes auth add/remove`, OAuth token
refreshes, memories, cron jobs, and writable skills can still change runtime
state. A switch does not reset those choices or roll back databases. Upstream
document options copy files; removing a declaration does not erase the old copy.

The terminal backend is `local` and uses the real user HOME. The workspace is a
starting directory, not a sandbox. Tools can access other paths with the user's
permissions. Disabling external login borrowing prevents automatic adoption of
Codex/Claude logins; it does not restrict shell access to those files.

## Data paths and removal

| Data | Linux host | macOS when enabled |
| --- | --- | --- |
| State root (`hermesHome`) | `/home/huangjh/.hermes` | `/Users/jinhaohuang/.hermes` |
| Workspace (`workingDirectory`) | `/home/huangjh/hermes-workspace` | `/Users/jinhaohuang/hermes-workspace` |
| Secret source (`environmentFiles`) | `/home/huangjh/.config/hermes/secrets.env` | Explicit runtime paths; the example above uses `~/.config/hermes/secrets.env` |
| Service logs | User journal for `hermes-agent` / `hermes-backend` | `~/Library/Logs/hermes-agent.log`, `hermes-agent.err.log`; corresponding `hermes-backend` files if enabled |

The state root contains `config.yaml`, the credential copy `.env`, `.managed`,
optional `auth.json` and MCP tokens, `state.db`, sessions, memories, cron jobs
and outputs, skills, plugins, caches, and application logs. `.restart-needed`
is a private, empty marker for a pending service restart. Paths can be overridden
per host; check the effective values before removing anything.

Set `hermes.enable = false` and switch to remove the managed program and services.
Confirm gateway, backend, and interactive processes have stopped. Disabling
preserves state, workspace files, secret sources, and the managed marker.
Permanent removal is separate: back up anything needed, then explicitly remove
the selected state root, workspace, dedicated secret files, and macOS log files.
Old Home Manager/nix-darwin generations retain software until generation cleanup
and garbage collection; Linux journal retention is separate.

Additional features can create data outside these paths: browser harness data
under `~/.config/browser-harness`, temporary sockets, custom profile launchers
under `~/.local/bin`, and files written by invoked tools. Review those individually;
do not delete shared tool directories blindly. Uninstalling cannot undo edits
to other projects or remove messages and records held by external services.

For platform commands, see [Linux setup](../../docs/linux.md#hermes) or
[macOS setup](../../docs/darwin.md#hermes).
