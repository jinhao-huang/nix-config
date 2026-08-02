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
  switch --flake .#mac
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

### Proton Pass session lifecycle

If the configuration was activated before Proton Pass was authenticated, stop
the already loaded SSH agent before logging in, then reactivate the
configuration:

```sh
launchctl bootout "gui/$UID/org.nix-community.home.proton-pass-ssh-agent" 2>/dev/null || true
pass-cli login
sudo darwin-rebuild switch --flake .#mac
```

Authentication and launch-agent lifecycles are intentionally managed
separately. Stop the agent before explicitly logging out so it cannot retain
loaded SSH keys in memory:

```sh
launchctl bootout "gui/$UID/org.nix-community.home.proton-pass-ssh-agent" 2>/dev/null || true
pass-cli logout
```

After logging in again, run `sudo darwin-rebuild switch --flake .#mac` to load
the agent in the current user session. Future user sessions load it
automatically.

## Subsequent rebuilds

```sh
sudo darwin-rebuild switch --flake .#mac
```

## How to update

### Update all input

nix flake update

### Update specific input

nix flake update <input-name>
