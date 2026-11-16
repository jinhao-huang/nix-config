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

## Music library

On the desktop Mac, clone [Metaweave](https://github.com/jinhao-huang/metaweave)
into the `musicLibrary.checkout` path in [the host inventory](../hosts/darwin.nix).
Switch warns if the skill or Telegram credentials file is missing and prints
the expected path. After switching, install the locked runtime from the
checkout. Repeat this step after a lockfile update.

```sh
uv sync --locked --no-dev --no-build --managed-python
```

Open OrbStack and set it to start at login. The [Nix profile](../profiles/home/music-library.nix)
sets up a user launch agent and pins the existing [Telegram MCP image](https://github.com/users/jinhao-huang/packages/container/package/telegram-mcp).
It connects the Hermes `music-library` profile to the container over loopback.
Switching over SSH works with Docker stopped. The agent runs in the logged-in
macOS session.

`switch` creates the `music-library` profile with its own sessions, memory, and
model credentials from the same Proton Pass entries used by `default`. With
default XDG paths it creates `telegram/` and `downloads/` under
`~/.local/share/metaweave/` with mode `0700`.

Use the [upstream login and migration tools](https://github.com/chigwell/telegram-mcp/tree/v3.3.20#quick-start)
to create a separate Telegram session and save `telegram.session` in the
`telegram/` directory. Last, put `TELEGRAM_API_ID` and `TELEGRAM_API_HASH` in
`~/.config/nix-config/telegram-mcp.env` as unquoted `KEY=value` lines. The file
starts the launch agent when present. Use mode `0600` for both credential files.
To limit MCP access to specific chats, set `TELEGRAM_ALLOWED_CHAT_IDS` to their
comma-separated Telegram IDs or `@usernames`.
For proxy settings, use upstream `TELEGRAM_PROXY_*` keys and a host reachable
from OrbStack.

Run `hermes -p music-library mcp test telegram-music` to check the connection.
The launch agent logs to `~/Library/Logs/telegram-music.log`. After editing the environment file, run
`launchctl kickstart -k "gui/$UID/org.nix-community.home.telegram-music"`.

In the existing Dashboard, select the `music-library` profile and open a new
chat. Name the channel and task, and review the exact request before sending.
Telegram MCP saves attachments up to 200 MiB in the Mac downloads directory.
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
