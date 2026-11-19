# macOS setup

English | [简体中文](darwin.zh-CN.md)

Run from the repository root as the regular user. Select the machine's role;
it is independent of the hardware model and macOS hostname:

```sh
deploy_host=laptop # Use desktop on the desktop Mac.
```

Set this variable again in each new shell.

## Before first activation

Nix and Git must already be installed. Check `username`, `homeDirectory`,
`authorizedKeyFiles`, and the application choices in
[hosts/darwin.nix](../hosts/darwin.nix) for the selected role. If Hermes is
enabled, check its [credential source](../modules/hermes/README.md#secrets-and-activation)
before activation.

If the build needs transparent proxying, place
the official Surge Mac release at `/Applications/Surge.app`, open it, and enable
Enhanced Mode first. Homebrew Bundle adopts this copy as the managed `surge`
cask during activation.

Authenticate Proton Pass before its launch agent starts:

```sh
nix --extra-experimental-features "nix-command flakes" \
  run .#proton-pass-cli -- login
```

## First activation

Activate nix-darwin once after the preparation above. This command also works
before `darwin-rebuild` is available:

```sh
nix --extra-experimental-features "nix-command flakes" \
  run .#deploy -- switch "$deploy_host"
```

Nix may ask to trust this flake's `cache.numtide.com` substituter and public key.
Choose `Allow always` or `yes for now` if you trust the repository and cache.
Declining disables that cache and can require local builds. Restart the terminal
after activation to load the environment.

## GitHub CLI

Sign in once after activation; later shells reuse the saved login:

```sh
gh auth login --web --git-protocol ssh --skip-ssh-key
gh auth status
```

The flags retain the existing agent setup; see
[GitHub CLI, SSH, and signing](../modules/gh/README.md) for protocol choices and
their effect on authentication. The token uses the system credential store when
available. Keep it out of Nix values; inject `GH_TOKEN` from a runtime secret
store for headless automation.

## Hermes

The [desktop role](../hosts/darwin.nix) enables Hermes and its Dashboard. Before
switching, store the MiniMax China subscription key in the Proton Pass field
referenced by `MINIMAX_CN_API_KEY` in the desktop inventory. New chats default
to MiniMax. To use DeepSeek for the current chat, enter
`/model deepseek-flash --provider deepseek --session`.

In Dashboard chats using MiniMax, attach an image to let the model inspect it
directly.

Follow the [HTTPS setup](../modules/tailscale/README.md#hermes-over-https) for
browser access. To chat in the terminal after activation, run:

```sh
hermes --tui
```

If the gateway is enabled, check it with:

```sh
launchctl print "gui/$UID/org.nix-community.home.hermes-agent"
tail -n 50 ~/Library/Logs/hermes-agent.err.log
```

Surge handles egress. To enable Hermes later or update it, follow the
[Hermes configuration and maintenance guide](../modules/hermes/README.md), then
use the routine rebuild flow. Do not run `hermes update`.

## Telegram MCP

Both Macs run a [pinned image](https://github.com/users/jinhao-huang/packages/container/package/telegram-mcp)
through a [Home Manager launch agent](../modules/telegram-mcp/default.nix).
Open OrbStack and set it to start at login. Switching over SSH works with Docker
stopped. The agent runs in the logged-in macOS session.

Both Macs store the session and downloads under `~/.local/share/telegram-mcp/`
by default. `switch` creates the `telegram/` and `downloads/` subdirectories
with mode `0700` and reports the path of any missing session or credentials file.

Check out `v3.3.20` and follow the [upstream login and migration guide](https://github.com/chigwell/telegram-mcp/blob/v3.3.20/README.md#quick-start)
on each Mac that lacks a session file. Each Mac needs its own Telegram session.
Put the API credentials in a temporary `.env` in that checkout. Generate a
session string or reuse one dedicated to this Mac. Save it in `.env`. The
migration command below reads `TELEGRAM_SESSION_STRING` (blank account label). For a labeled string,
add the matching `--account` argument, e.g. `--account secondary` for
`TELEGRAM_SESSION_STRING_SECONDARY`.

```sh
uv sync --locked --no-dev --no-install-project --no-build
uv run --no-sync python session_string_generator.py
session_dir="${XDG_DATA_HOME:-$HOME/.local/share}/telegram-mcp/telegram"
install -d -m 0700 "$session_dir"
uv run --no-sync python migrate_session.py --target "$session_dir/telegram.session"
```

After migration, put the service credentials in
`${XDG_CONFIG_HOME:-$HOME/.config}/nix-config/telegram-mcp.env` (create the parent
directory if needed), then remove the temporary `.env`. Use unquoted `KEY=value`
lines for `TELEGRAM_API_ID` and `TELEGRAM_API_HASH`. You can reuse this pair on
both Macs. Set `TELEGRAM_ALLOWED_CHAT_IDS` to the comma-separated Telegram IDs or
`@usernames` you want the service to access. Use mode `0600` for the session
and service credentials files. If you configure `TELEGRAM_PROXY_*`, use an
address reachable from OrbStack.

Set your MCP client's Streamable HTTP URL to `http://127.0.0.1:8765/mcp`.
Both Macs expose read-only tools and the same
[write tools](../profiles/home/darwin.nix). Check the container and the tools
listed by the client after connecting, then download a small attachment to verify
the local `downloads/` directory.

```sh
docker --context orbstack compose -f "${XDG_CONFIG_HOME:-$HOME/.config}/nix-config/telegram-mcp/compose.yaml" ps
```

The launch agent logs to `~/Library/Logs/telegram-mcp.log`. After editing the
environment file, run `launchctl kickstart -k "gui/$UID/org.nix-community.home.telegram-mcp"`.

## Music library

On the desktop Mac, clone [Metaweave](https://github.com/jinhao-huang/metaweave)
into the `musicLibrary.checkout` path in [the host inventory](../hosts/darwin.nix).
With Hermes enabled, `switch` warns if the skill is missing. After switching,
install the locked runtime from the checkout. Repeat after a lockfile update.

```sh
uv sync --locked --no-dev --no-build --managed-python
```

`switch` creates the `music-library` profile with its own sessions and memory.
It uses the same Proton Pass model credentials as `default`. Set up [Telegram
MCP](#telegram-mcp) on the desktop, then run
`hermes -p music-library mcp test telegram-mcp` to check the connection.

In the existing Dashboard, select the `music-library` profile and open a new
chat. Name the channel and task, and review the exact request before sending.
Telegram MCP saves attachments up to 200 MiB in its `downloads/` directory,
the working directory for `music-library`.
For larger attachments, download them to this Mac using a
Telegram client. For web shares, follow the skill's download workflow and put the
files on this Mac before intake. Keep task records outside the music root and use
the configured SSH host for in-place NAS work. Install the standalone skill
runtime there before the first such task.

## Remote access and Harness

- [Tailscale ingress](../modules/tailscale/README.md) covers enrollment,
  connection checks, and logs. Surge continues to handle egress.
- [macOS Remote Login](../profiles/system/darwin/remote-login/README.md) uses
  separate authorization from Tailscale SSH.
- Open **DeepSeek Harness**, installed by Homebrew, and add an API key in
  **Settings → Models**. Credentials and sessions stay under `~/.dsh`.
  [Harness policy](../modules/deepseek-harness/default.nix) disables telemetry,
  additional session-log uploads, and Desktop product analytics; model requests
  still send task context.

## Maintenance and recovery

For routine rebuilds and input updates, see the [README](../README.md).
The following Proton Pass steps are recovery and logout procedures, not part
of first setup.

If activation preceded authentication, stop the agent before logging in, then
reactivate:

```sh
launchctl bootout "gui/$UID/org.nix-community.home.proton-pass-ssh-agent" 2>/dev/null || true
pass-cli login
nix run .#deploy -- switch "$deploy_host"
```

Stop the agent before explicitly logging out so loaded SSH keys leave memory:

```sh
launchctl bootout "gui/$UID/org.nix-community.home.proton-pass-ssh-agent" 2>/dev/null || true
pass-cli logout
```

After logging in again, switch to reload the agent in the current user session.
Future user sessions load it automatically.
