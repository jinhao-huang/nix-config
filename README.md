## First-time setup

On a new machine, `darwin-rebuild` is not available until nix-darwin has been
activated for the first time. From the repository root, run:

```sh
sudo -H nix --extra-experimental-features "nix-command flakes" \
  run nix-darwin/nix-darwin-26.05#darwin-rebuild -- \
  switch --flake .#mac
```

If resources required by the build are not directly reachable, use any HTTP
proxy endpoint that is accessible from the new machine. Replace the example
address with the proxy host and port, and run:

```sh
bootstrap_proxy_url="http://192.168.1.2:6152"
sudo -H env \
  http_proxy="$bootstrap_proxy_url" \
  https_proxy="$bootstrap_proxy_url" \
  HTTP_PROXY="$bootstrap_proxy_url" \
  HTTPS_PROXY="$bootstrap_proxy_url" \
  nix --extra-experimental-features "nix-command flakes" \
  run nix-darwin/nix-darwin-26.05#darwin-rebuild -- \
  switch --flake .#mac
```

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

## Subsequent rebuilds

```sh
sudo darwin-rebuild switch --flake .#mac
```

## How to update

### Update all input

nix flake update

### Update specific input

nix flake update <input-name>
