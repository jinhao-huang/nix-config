{
  config,
  lib,
  pkgs,
  ...
}:
let
  cfg = config.modules.deepseek-harness;
  serviceCfg = cfg.service;
  publicAuthority =
    serviceCfg.publicHost
    + lib.optionalString (serviceCfg.publicPort != 443) ":${toString serviceCfg.publicPort}";
  yamlFormat = pkgs.formats.yaml { };
  # Serve terminates TLS but does not add Secure to the upstream's cookies.
  proxyConfig = pkgs.writeText "dsh-Caddyfile" ''
    {
      admin off
      persist_config off
      auto_https off
    }
    :${toString serviceCfg.proxyPort} {
      bind 127.0.0.1
      reverse_proxy 127.0.0.1:${toString serviceCfg.port} {
        header_down Set-Cookie "^(.+)$" "$1; Secure"
      }
    }
  '';
in
{
  _class = "homeManager";

  options.modules.deepseek-harness = {
    enable = lib.mkEnableOption "DeepSeek Harness policy";

    package = lib.mkOption {
      type = lib.types.package;
      description = "DeepSeek Harness CLI package selected by the flake for the Linux service.";
    };

    service = {
      enable = lib.mkEnableOption "the persistent Linux DeepSeek Harness Web service";
      publicHost = lib.mkOption {
        type = lib.types.strMatching "[a-zA-Z0-9][a-zA-Z0-9.-]*";
        description = "Tailnet HTTPS hostname advertised by the Web service.";
      };
      publicPort = lib.mkOption {
        type = lib.types.ints.between 1 65535;
        default = 443;
        description = "Public HTTPS port advertised by the Web service.";
      };
      port = lib.mkOption {
        type = lib.types.ints.between 1 65535;
        default = 3080;
        description = "Loopback port for the Harness backend.";
      };
      proxyPort = lib.mkOption {
        type = lib.types.ints.between 1 65535;
        default = 3081;
        description = "Loopback port for the cookie-rewriting proxy used by Tailscale Serve.";
      };
    };
  };

  config = lib.mkIf cfg.enable {
    assertions = [
      {
        assertion = pkgs.stdenv.isDarwin || pkgs.stdenv.isLinux;
        message = "DeepSeek Harness requires macOS or Linux.";
      }
      {
        assertion = serviceCfg.enable -> pkgs.stdenv.isLinux;
        message = "The DeepSeek Harness systemd user service requires Linux.";
      }
      {
        assertion = serviceCfg.enable -> serviceCfg.port != serviceCfg.proxyPort;
        message = "DeepSeek Harness backend and proxy ports must differ.";
      }
    ];

    home.packages = lib.optionals serviceCfg.enable [ cfg.package ];

    # Home Manager has no native dsh module. Keep only fixed, non-secret policy
    # in the home patch; dsh owns writable profiles, credentials, and sessions.
    home.file.".dsh/cordis.patch.yml".source = yamlFormat.generate "dsh-policy.yaml" (
      [
        {
          id = "session-telemetry-otel";
          disabled = true;
        }
        {
          id = "session-log-deepseek";
          config.enabled = false;
        }
      ]
      ++ lib.optionals pkgs.stdenv.isDarwin [
        {
          id = "product-analytics";
          config.enabled = false;
        }
      ]
    );

    systemd.user.services = lib.mkIf serviceCfg.enable {
      deepseek-harness = {
        Unit.Description = "DeepSeek Harness Web workspace";
        Service = {
          ExecStart = lib.escapeShellArgs [
            (lib.getExe cfg.package)
            "web"
            "--no-open"
            "--host"
            "127.0.0.1"
            "--port"
            (toString serviceCfg.port)
            "--public-url"
            "https://${publicAuthority}/"
            "--trusted-host"
            publicAuthority
          ];
          WorkingDirectory = config.home.homeDirectory;
          # A user service does not run shell integration; make plugin pnpm
          # and the managed development tools available without a login shell.
          Environment = [
            "PATH=${lib.makeBinPath [ pkgs.pnpm ]}:${config.home.profileDirectory}/bin:${config.home.homeDirectory}/.local/bin:/usr/local/bin:/usr/bin:/bin"
          ];
          UMask = "0077";
          Restart = "on-failure";
          RestartSec = 5;
          TimeoutStopSec = 30;
        };
        Install.WantedBy = [ "default.target" ];
      };

      # Home Manager has no native Caddy service module. This private proxy
      # preserves Host and WebSocket upgrades and only strengthens cookies.
      deepseek-harness-proxy = {
        Unit = {
          Description = "DeepSeek Harness HTTPS cookie policy";
          After = [ "deepseek-harness.service" ];
          Requires = [ "deepseek-harness.service" ];
          PartOf = [ "deepseek-harness.service" ];
        };
        Service = {
          ExecStartPre = "${lib.getExe pkgs.caddy} validate --config ${proxyConfig} --adapter caddyfile";
          ExecStart = "${lib.getExe pkgs.caddy} run --config ${proxyConfig} --adapter caddyfile";
          UMask = "0077";
          NoNewPrivileges = true;
          Restart = "on-failure";
          RestartSec = 5;
        };
        Install.WantedBy = [ "deepseek-harness.service" ];
      };
    };
  };
}
