# Hermes

The Linux profile runs Hermes through the official Home Manager service module.
Configuration and credentials are declarative; sessions and memory remain writable.

## Per-host configuration

Set `hermes` in [hosts/linux.nix](../../hosts/linux.nix); its fields map to official
[`services.hermes-agent` options](https://hermes-agent.nousresearch.com/docs/getting-started/nix-setup#home-manager-module).
Use `hermes.enable = false` to disable it for one host. Shared defaults live in
[the Linux profile](../../profiles/home/linux.nix).

### Local overrides

Add host-specific values to Git-ignored `hosts/inventory.local.nix`. Hermes
attributes merge recursively; scalars and lists replace their tracked values.
For an OpenAI-compatible endpoint, replace these example values:

```nix
{
  iscas-r750xa.hermes = {
    settings.model = {
      provider = "custom";
      default = "private-model-id";
      base_url = "https://llm.example.internal/v1";
      api_mode = "chat_completions";
    };
    environment.TELEGRAM_ALLOWED_USERS = "123456789";
  };
}
```

Local Nix values still enter the Nix store. Keep keys and tokens in private files.
Use the [deployment command](../../README.md#build-and-switch) to load local overrides.

## Secrets and Telegram

The tracked host enables Telegram and reads
`/home/huangjh/.config/hermes/secrets.env`. Create this user-owned file with mode
`0600` or `0400` and its parent with mode `0700`:

```dotenv
OPENAI_API_KEY=replace-on-the-server
TELEGRAM_BOT_TOKEN=replace-on-the-server
```

`TELEGRAM_ALLOWED_USERS` takes comma-separated numeric user IDs. To receive
proactive messages or cron results, also set `environment.TELEGRAM_HOME_CHANNEL`.
Activation rejects missing model settings, unreadable or non-private secret
files, missing bot tokens, invalid user IDs, and public Telegram access. Inputs
must exist before switching; builds do not require them. These checks
do not verify authentication with external services.

## Configuration ownership

Switch to apply changes, including secret-file updates. Activation replaces the
full `config.yaml`, synchronizes `.env`, and locks interactive configuration;
edit Nix instead of running setup or config mutation commands. Environment files
are merged after public values, in order, with later files winning.

The module uses upstream `moduleCommon.nix` to render a complete native
`configFile`, so removed settings disappear. Check that interface on input updates.

For operation and upgrades, see [Linux setup](../../docs/linux.md#hermes).
