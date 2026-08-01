## First-time setup

On a new machine, `darwin-rebuild` is not available until nix-darwin has been
activated for the first time. From the repository root, run:

```sh
sudo nix --extra-experimental-features "nix-command flakes" \
  run nix-darwin/nix-darwin-26.05#darwin-rebuild -- \
  switch --flake .#mac
```

Restart the terminal after the command completes so the updated environment is
loaded.

## Subsequent rebuilds

```sh
sudo darwin-rebuild switch --flake .#mac
```

## How to update

### Update all input

nix flake update

### Update specific input

nix flake update <input-name>
