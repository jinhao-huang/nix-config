{
  config,
  lib,
  pkgs,
  ...
}:
let
  cfg = config.modules.sing-box;
  configDirectory = "${config.xdg.configHome}/sing-box";
  stateDirectory = "${config.xdg.stateHome}/sing-box";
  localDomains = lib.unique ([ "localhost" ] ++ cfg.routing.directDomains);
  noProxy = lib.unique (
    [
      "127.0.0.1"
      "::1"
    ]
    ++ localDomains
    ++ cfg.routing.directDomainSuffixes
  );
  cnDomains = pkgs.fetchurl {
    url = "https://raw.githubusercontent.com/SagerNet/sing-geosite/ea962e34bf255b69f3a66690e4a53900d48b48ea/geosite-cn.srs";
    hash = "sha256-fnqVvxbGvMfAJbhteJsuG5wU84zjN3fliEFmFcui5A8=";
  };
  directRule =
    fields:
    fields
    // {
      action = "route";
      outbound = "direct";
    };
  baseConfig = {
    log.level = "warn";
    inbounds = [
      {
        type = "mixed";
        tag = "local";
        listen = "127.0.0.1";
        listen_port = cfg.listenPort;
        set_system_proxy = false;
      }
    ];
    dns = {
      servers = [
        {
          type = "local";
          tag = "local-dns";
        }
      ];
      final = "local-dns";
    };
    outbounds = [
      {
        type = "direct";
        tag = "direct";
        domain_resolver = "local-dns";
      }
    ];
    route = {
      default_domain_resolver = "local-dns";
      rule_set = [
        {
          type = "local";
          tag = "cn-domains";
          format = "binary";
          path = toString cnDomains;
        }
      ];
      rules = [
        (directRule { ip_is_private = true; })
      ]
      ++ [ (directRule { domain = localDomains; }) ]
      ++ lib.optional (cfg.routing.directDomainSuffixes != [ ]) (directRule {
        domain_suffix = cfg.routing.directDomainSuffixes;
      })
      ++ lib.optional (cfg.routing.directIpCidrs != [ ]) (directRule {
        ip_cidr = cfg.routing.directIpCidrs;
      })
      ++ lib.optional (cfg.routing.proxyDomainSuffixes != [ ]) {
        domain_suffix = cfg.routing.proxyDomainSuffixes;
        action = "route";
        outbound = "proxy";
      }
      ++ [ (directRule { rule_set = "cn-domains"; }) ];
      final = "proxy";
    };
  };
  policy = pkgs.writeText "sing-box-policy.json" (
    builtins.toJSON {
      inherit configDirectory stateDirectory baseConfig;
      inherit (cfg) listenPort nodesFile;
      requestFile = cfg.subscription.requestFile;
      credentialsFile = cfg.proxyCredentialsFile;
      username = config.home.username;
      singBox = lib.getExe cfg.package;
      packageId = builtins.hashString "sha256" (lib.getExe cfg.package);
      curl = lib.getExe pkgs.curl;
      systemctl = lib.getExe' pkgs.systemd "systemctl";
      inherit noProxy;
    }
  );
  runtime = "${lib.getExe pkgs.python3} ${./runtime.py} ${policy}";
  withProxy = pkgs.writeShellApplication {
    name = "with-proxy";
    text = ''
      exec ${runtime} with-proxy "$@"
    '';
  };
  privatePath = path: lib.hasPrefix "/" path && !(lib.hasPrefix "${builtins.storeDir}/" path);
in
{
  _class = "homeManager";

  options.modules.sing-box = {
    enable = lib.mkEnableOption "an authenticated local HTTP/SOCKS proxy with private proxy nodes";
    package = lib.mkPackageOption pkgs "sing-box" { example = "pkgs.sing-box"; };
    listenPort = lib.mkOption {
      type = lib.types.port;
      example = 21009;
      description = ''
        Fixed loopback HTTP/SOCKS port, required when enabled. The port must be
        between 1024 and 65535; conflicts abort activation. The Linux profile
        also checks for conflicts with the Harness backend and proxy.
      '';
    };
    subscription.requestFile = lib.mkOption {
      type = lib.types.nullOr lib.types.str;
      default = null;
      example = "/home/alice/.config/sing-box/lab.curl";
      description = ''
        Private runtime curl configuration containing the HTTPS subscription URL
        and headers. The response must be native sing-box JSON with an outbounds
        array, at most 8 MiB. Null disables subscription downloads. Configure
        this option, nodesFile, or both; both sources join the same URLTest group.
        Use an absolute path outside Git and the Nix store. Activation repairs
        permissions only in the sing-box XDG config and state directories;
        other locations must already have directory mode 0700 and file mode
        0600 or 0400. Files must be user-owned and readable, with no symlinks
        or multiple hard links. Nix never reads their contents.
      '';
    };
    nodesFile = lib.mkOption {
      type = lib.types.nullOr lib.types.str;
      default = null;
      example = "/home/alice/.config/sing-box/nodes.json";
      description = ''
        Private runtime native sing-box JSON with an outbounds array, at most
        8 MiB. Only independent proxy nodes are imported; listeners, routing,
        DNS, and proxy groups remain module-managed. Node tags must be unique
        within each source; local and subscription tags are namespaced separately.
        Changes take effect on the next switch. Null disables local node input.
        Configure this option, subscription.requestFile, or both. Use an absolute
        path outside Git and the Nix store. Activation repairs permissions only
        in the sing-box XDG config and state directories; other locations must
        already have directory mode 0700 and file mode 0600 or 0400. Files must
        be user-owned and readable, with no symlinks or multiple hard links.
        Nix never reads their contents. Share links are not supported.
      '';
    };
    proxyCredentialsFile = lib.mkOption {
      type = lib.types.str;
      default = "${stateDirectory}/auth.json";
      defaultText = lib.literalExpression ''"''${config.xdg.stateHome}/sing-box/auth.json"'';
      example = "/home/alice/.local/state/sing-box/lab-auth.json";
      description = ''
        Private username/password JSON, generated once if absent. Use an
        absolute path outside Git and the Nix store. The file has mode 0600 and
        remains runtime state; Nix never reads its contents. Permissions are
        repaired only in the sing-box XDG config and state directories. A custom
        parent directory elsewhere must already exist with mode 0700.
      '';
    };
    routing = {
      directDomains = lib.mkOption {
        type = lib.types.listOf lib.types.str;
        default = [ ];
        example = [ "git.lab.example" ];
        description = ''
          Additional exact hostnames resolved locally and routed directly.
          localhost is always included. These names also enter no_proxy and
          NO_PROXY for login shells and with-proxy commands.
        '';
      };
      directDomainSuffixes = lib.mkOption {
        type = lib.types.listOf lib.types.str;
        default = [ ];
        example = [ "internal" ];
        description = "Local domain suffixes, without a leading dot; also included in no_proxy.";
      };
      directIpCidrs = lib.mkOption {
        type = lib.types.listOf lib.types.str;
        default = [ ];
        example = [ "203.0.113.0/24" ];
        description = ''
          Additional directly reachable campus or LAN networks in CIDR notation.
          Private IP destinations already go direct. These rules apply inside
          sing-box and are not added to no_proxy.
        '';
      };
      proxyDomainSuffixes = lib.mkOption {
        type = lib.types.listOf lib.types.str;
        default = [ ];
        example = [ "proxy.example" ];
        description = ''
          Domain suffixes routed through proxy nodes before the China
          domain set is checked. Private destinations and explicit direct
          domain, suffix, and CIDR rules take precedence.
        '';
      };
    };
  };

  config = lib.mkIf cfg.enable {
    assertions = [
      (lib.hm.assertions.assertPlatform "modules.sing-box" pkgs lib.platforms.linux)
      {
        assertion = cfg.listenPort >= 1024;
        message = "modules.sing-box.listenPort must be an unprivileged port (1024–65535).";
      }
      {
        assertion = cfg.subscription.requestFile != null || cfg.nodesFile != null;
        message = "sing-box requires subscription.requestFile, nodesFile, or both.";
      }
      {
        assertion = lib.all privatePath (
          [ cfg.proxyCredentialsFile ]
          ++ lib.filter (path: path != null) [
            cfg.subscription.requestFile
            cfg.nodesFile
          ]
        );
        message = "sing-box secret paths must be absolute runtime paths outside the Nix store.";
      }
      {
        assertion = lib.all (
          suffix: suffix != "" && !(lib.hasPrefix "." suffix)
        ) cfg.routing.directDomainSuffixes;
        message = "sing-box direct domain suffixes must be nonempty and have no leading dot.";
      }
    ];

    home.packages = [
      cfg.package
      withProxy
    ];
    home.sessionVariables = {
      no_proxy = lib.concatStringsSep "," noProxy;
      NO_PROXY = lib.concatStringsSep "," noProxy;
    };

    # No native Home Manager sing-box module exists. Runtime secret synchronization
    # also needs ownership and no-follow checks before repairing permissions.
    home.activation.checkSingBoxInputs = lib.hm.dag.entryBefore [ "writeBoundary" ] ''
      run ${runtime} check_inputs
    '';
    home.activation.prepareSingBox =
      lib.hm.dag.entryBetween [ "linkGeneration" "installPackages" ] [ "writeBoundary" ]
        ''
          run ${runtime} initialize
          if [[ ! -v DRY_RUN ]]; then
            exec {singBoxLockFd}>${lib.escapeShellArg "${stateDirectory}/activation.lock"}
            if ! ${lib.getExe' pkgs.util-linux "flock"} --timeout 90 "$singBoxLockFd"; then
              echo "Timed out waiting for another sing-box activation." >&2
              exit 1
            fi
            singBoxCandidate="$(run ${runtime} prepare)"
          else
            run ${runtime} prepare
          fi
        '';
    home.activation.applySingBox =
      lib.hm.dag.entryAfter [ "reloadSystemd" "installPackages" "onFilesChange" ]
        ''
          run ${runtime} apply "''${singBoxCandidate:-<prepared-snapshot>}"
          if [[ ! -v DRY_RUN ]]; then
            exec {singBoxLockFd}>&-
          fi
        '';

    systemd.user.services.sing-box = {
      Unit = {
        Description = "Authenticated sing-box development proxy";
        # Activation validates and commits snapshots; sd-switch must not restart early.
        X-SwitchMethod = "keep-old";
        ConditionPathExists = "${stateDirectory}/current/config.json";
        StartLimitIntervalSec = 30;
        StartLimitBurst = 3;
      };
      Service = {
        ExecStart = "${lib.getExe cfg.package} run -c ${lib.escapeShellArg "${stateDirectory}/current/config.json"} -D ${lib.escapeShellArg stateDirectory}";
        UMask = "0077";
        NoNewPrivileges = true;
        Restart = "on-failure";
        RestartSec = 3;
        TimeoutStartSec = 15;
        TimeoutStopSec = 15;
      };
      Install.WantedBy = [ "default.target" ];
    };
  };
}
