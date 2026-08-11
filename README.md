## Choose a Darwin profile

Set the profile for the current machine before running the commands below:

```sh
darwin_profile=laptop
# Use `desktop` on the desktop Mac.
```

Set the variable again after opening a new shell. The profile names describe
the machine's role and are independent of its hardware model or macOS hostname.

## First-time setup

On a new machine, `darwin-rebuild` is not available until nix-darwin has been
activated for the first time. Before the first activation, authenticate Proton
Pass as the regular user so its launch agent does not race with interactive
session initialization:

```sh
nix --extra-experimental-features "nix-command flakes" \
  run .#proton-pass-cli -- login
```

Then run the initial activation from the repository root:

```sh
sudo -H nix --extra-experimental-features "nix-command flakes" \
  run nix-darwin/nix-darwin-26.05#darwin-rebuild -- \
  switch --flake ".#$darwin_profile"
```

If the full build requires transparent proxying, download the latest official
Surge Mac release, place `Surge.app` at `/Applications/Surge.app`, open it, and
enable Enhanced Mode before running the command above. Homebrew Bundle uses its
adoption flow for an existing app declared as a cask, so the full activation
registers the manually placed application as the managed `surge` cask instead
of installing a conflicting second copy.

The `-H` option gives the root process its own home directory and avoids Nix's
warning that `/Users/jinhaohuang` is not owned by root. It does not change the
user targeted by the nix-darwin or Home Manager configuration.

During the first build, Nix asks whether to trust the `cache.numtide.com`
substituter and its public key declared by this flake. This is a security prompt,
not a build failure. Choose `Allow always` when the repository and the Numtide
cache are trusted, or `yes for now` to allow them only for the current build.
Declining the prompt disables that binary cache and may cause more packages to
be built locally.

Restart the terminal after the command completes so the updated environment is
loaded.

### GitHub CLI authentication

Home Manager installs GitHub CLI and configures it to use SSH for Git
operations. Authentication remains machine-local runtime state so credentials
never enter the repository or the Nix store. After the first activation, sign
in as the regular user:

```sh
gh auth login --web --git-protocol ssh --skip-ssh-key
gh auth status
```

The `--skip-ssh-key` option keeps SSH key management with the Proton Pass agent.
The interactive login stores the OAuth token in the system credential store
when available. Do not add tokens to `programs.gh`, `home.sessionVariables`, or
other Nix values. For headless automation, inject `GH_TOKEN` from the runtime
secret store instead of persisting it in this configuration.

### Proton Pass session lifecycle

If the configuration was activated before Proton Pass was authenticated, stop
the already loaded SSH agent before logging in, then reactivate the
configuration:

```sh
launchctl bootout "gui/$UID/org.nix-community.home.proton-pass-ssh-agent" 2>/dev/null || true
pass-cli login
sudo darwin-rebuild switch --flake ".#$darwin_profile"
```

Authentication and launch-agent lifecycles are intentionally managed
separately. Stop the agent before explicitly logging out so it cannot retain
loaded SSH keys in memory:

```sh
launchctl bootout "gui/$UID/org.nix-community.home.proton-pass-ssh-agent" 2>/dev/null || true
pass-cli logout
```

After logging in again, set `darwin_profile` again and run
`sudo darwin-rebuild switch --flake ".#$darwin_profile"` to load the agent in
the current user session. Future user sessions load it automatically.

## Subsequent rebuilds

```sh
darwin_profile=laptop # Use `desktop` on the desktop Mac.
sudo darwin-rebuild switch --flake ".#$darwin_profile"
```

## How to update

### Update all input

nix flake update

### Update specific input

nix flake update <input-name>
