{
  config,
  hermesAgent,
  linuxHost,
  lib,
  pkgs,
  ...
}:
let
  hermes = config.services.hermes-agent;
  hermesModule = import "${hermesAgent}/nix/moduleCommon.nix" { inherit lib; };
  inherit (linuxHost) hermesDashboard;
  serveHermes = linuxHost ? hermesDashboard;
  hermesTarget = "http://127.0.0.1:${toString hermes.backend.port}";
  hermesServeUnit = import ../../modules/tailscale/serve-unit.nix {
    inherit lib;
    inherit (config.modules.tailscale) package;
    inherit (hermesDashboard) httpsPort;
    target = hermesTarget;
    guard = import ../../modules/hermes/serve-guard.nix {
      inherit lib pkgs;
      inherit (hermesDashboard) url;
      target = hermesTarget;
    };
  };
  ensureLinger = pkgs.writeShellApplication {
    name = "ensure-user-linger";
    runtimeInputs = [
      pkgs.coreutils
      pkgs.systemd
    ];
    text = builtins.readFile ./ensure-linger.sh;
  };
  servicePorts =
    lib.optional config.modules.sing-box.enable config.modules.sing-box.listenPort
    ++
      lib.optionals
        (config.modules.deepseek-harness.enable && config.modules.deepseek-harness.service.enable)
        [
          config.modules.deepseek-harness.service.port
          config.modules.deepseek-harness.service.proxyPort
          config.modules.deepseek-harness.service.publicPort
        ]
    ++ lib.optional (hermes.enable && hermes.backend.mode != "none") hermes.backend.port
    ++ lib.optional serveHermes hermesDashboard.httpsPort;
in
{
  imports = [
    ./common.nix
    ./hermes
    ../../modules/mise
    ../../modules/docker-ghcr
    ../../modules/pi
    ../../modules/deepseek-harness
    ../../modules/sing-box
    ../../modules/tailscale/home-manager.nix
  ];

  home.stateVersion = "26.05";
  home.sessionVariables.XDG_RUNTIME_DIR = "\${XDG_RUNTIME_DIR:-/run/user/$(${lib.getExe' pkgs.coreutils "id"} -u)}";
  # Bash also reads .bashrc for non-interactive SSH commands, before its guard.
  programs.bash.bashrcExtra = ''
    . "${config.home.sessionVariablesPackage}/etc/profile.d/hm-session-vars.sh"
  '';
  modules.bash.enable = true;
  modules.mise.enable = true;
  modules.pi.enable = true;
  services.hermes-agent = {
    settings = lib.mkMerge [
      (lib.mkBefore {
        agent = {
          environment_hint = ''
            Respond in Chinese unless the user requests another language.
            Home Manager manages this Linux user environment. Use systemctl --user
            for user services; the host OS and Nix daemon are administrator-owned.
          ''
          + lib.optionalString config.modules.sing-box.enable ''
            For external HTTP/SOCKS access, run commands that support proxy environment
            variables through with-proxy COMMAND [ARGUMENT ...], for example:
            with-proxy curl -I https://github.com
            Run local-only commands normally. The wrapper requires the sing-box user
            service; if unavailable, inspect systemctl --user status sing-box and
            journalctl --user -u sing-box -n 50 --no-pager before retrying.
            SSH transports and tools that ignore proxy variables need their own routing.
            Keep proxy credentials and subscription data out of messages and logs.
          '';
        };
      })
      (lib.mkIf serveHermes { dashboard.public_url = hermesDashboard.url; })
    ];
  };
  modules.deepseek-harness = {
    enable = true;
    service = {
      enable = true;
      publicHost = linuxHost.tailnetHost;
    };
  };
  modules.ai-agents = {
    environment = ''
      ## Local Execution Environment

      - Home Manager manages this Linux user environment. The host operating system and Nix daemon remain administrator-owned; use `systemctl --user` for managed user services.
    ''
    + lib.optionalString config.modules.sing-box.enable ''

      ### Network Access

      - For external HTTP/SOCKS access, run commands that support proxy environment variables through `with-proxy COMMAND [ARGUMENT ...]`, for example `with-proxy curl -I https://github.com`. Local-only commands can run normally.
      - The wrapper checks the managed sing-box user service and injects its credentials and bypass list into the child environment. It does not start the service; SSH transports, independent daemons, and tools that ignore proxy environment variables need their own network configuration.
      - If the wrapper reports the proxy unavailable, inspect `systemctl --user status sing-box` and `journalctl --user -u sing-box -n 50 --no-pager` before retrying. Keep credentials and subscription data out of prompts and logs.
    '';
  };
  modules.sing-box.enable = lib.mkDefault true;
  home.activation.restartHermes = lib.mkIf hermes.enable (
    lib.hm.dag.entryAfter [ "applySingBox" ] (lib.mkDefault "")
  );
  # Both upstream units can use the same proxy integration.
  systemd.user.services = lib.mkMerge [
    (lib.mkIf (hermes.enable && hermes.backend.mode != "none") {
      hermes-backend.Service.Environment = [ "TERMINFO_DIRS=${pkgs.ncurses}/share/terminfo" ];
    })
    (lib.mkIf (hermes.enable && config.modules.sing-box.enable) (
      lib.genAttrs
        (
          lib.optional hermes.gateway.enable "hermes-agent"
          ++ lib.optional (hermes.backend.mode != "none") "hermes-backend"
        )
        (name: {
          Unit = {
            After = [ "sing-box.service" ];
            Requires = [ "sing-box.service" ];
            PartOf = [ "sing-box.service" ];
          };
          # Keep the upstream default.target link so sd-switch starts new units.
          Install.WantedBy = [ "sing-box.service" ];
          Service.Environment = lib.mkAfter [
            "PATH=${
              lib.makeBinPath (
                hermesModule.processPath {
                  inherit pkgs;
                  cfg = hermes;
                }
              )
            }:${config.home.path}/bin"
          ];
          Service.ExecStart = lib.mkForce (
            lib.escapeShellArgs (
              [ "${config.home.path}/bin/with-proxy" ]
              ++ (
                if name == "hermes-agent" then
                  hermesModule.gatewayArgv hermes
                else
                  hermesModule.backendArgv {
                    inherit pkgs;
                    cfg = hermes;
                  }
              )
            )
          );
        })
    ))
    {
      tailscale-serve-hermes = lib.mkIf serveHermes (
        lib.mkMerge [
          hermesServeUnit
          {
            Unit = {
              After = [
                "default.target"
                "hermes-backend.service"
              ];
              Requires = [ "hermes-backend.service" ];
              PartOf = [ "hermes-backend.service" ];
            };
            # sd-switch starts newly installed units through active targets.
            Install.WantedBy = [
              "default.target"
              "hermes-backend.service"
            ];
          }
        ]
      );
    }
    {
      tailscale-serve = {
        Unit = {
          After = [ "deepseek-harness-proxy.service" ];
          Requires = [ "deepseek-harness-proxy.service" ];
          PartOf = [ "deepseek-harness-proxy.service" ];
        };
        Install.WantedBy = [ "deepseek-harness-proxy.service" ];
      };
    }
  ];
  modules.tailscale = {
    enable = true;
    incoming.enable = true;
    outboundProxy.enable = false;
    ssh.enable = false;
    serve = {
      enable = true;
      httpsPort = config.modules.deepseek-harness.service.publicPort;
      target = "http://127.0.0.1:${toString config.modules.deepseek-harness.service.proxyPort}";
    };
  };

  assertions = [
    {
      assertion = lib.length (lib.unique servicePorts) == lib.length servicePorts;
      message = "Linux service ports must be distinct, including the tailnet HTTPS ports.";
    }
  ]
  ++ lib.optional serveHermes {
    assertion =
      hermes.backend.host == "127.0.0.1" && hermes.settings.dashboard.public_url == hermesDashboard.url;
    message = "Hermes Serve requires a loopback bind and the configured tailnet URL.";
  };

  home.activation.ensureUserLinger =
    lib.hm.dag.entryBetween [ "prepareSingBox" "linkGeneration" "installPackages" ] [ "writeBoundary" ]
      ''
        run ${lib.getExe ensureLinger}
      '';

  xdg.enable = true;
  targets.genericLinux = {
    enable = true;
    # GPU integration requires host setup; keep the CLI profile unprivileged.
    gpu.enable = false;
  };

  # Select activation and shell integration tools; the host owns the daemon.
  nix.package = pkgs.lixPackageSets.stable.lix;
  nix.settings.extra-experimental-features = [
    "nix-command"
    "flakes"
  ];

  home.packages = [ pkgs.ncurses ];
  home.sessionSearchVariables.TERMINFO_DIRS = [
    "${config.home.profileDirectory}/share/terminfo"
    "/etc/terminfo"
    "/lib/terminfo"
    "/usr/share/terminfo"
  ];
}
