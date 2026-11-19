{
  config,
  lib,
  pkgs,
  ...
}:
let
  cfg = config.modules.telegram-mcp;
  dataDirectory = "${config.xdg.dataHome}/telegram-mcp";
  sessionDirectory = "${dataDirectory}/telegram";
  sessionName = "telegram";
  sessionFile = "${sessionDirectory}/${sessionName}.session";
  envFile = "${config.xdg.configHome}/nix-config/telegram-mcp.env";
  port = "8765";
  orbstackBin = "/Applications/OrbStack.app/Contents/MacOS/xbin";
  logFile = "${config.home.homeDirectory}/Library/Logs/telegram-mcp.log";
  bind = source: target: {
    type = "bind";
    inherit source target;
    bind.create_host_path = false;
  };
  compose = (pkgs.formats.json { }).generate "telegram-mcp-compose.json" {
    name = "telegram-mcp";
    services.telegram-mcp = {
      image = "ghcr.io/jinhao-huang/telegram-mcp:v3.3.20-3@sha256:8d622d81e4c07d3c0e5185edc99bd08523330c529f9b93d9a3fc8a9e606f6bde";
      ports = [ "127.0.0.1:${port}:${port}" ];
      env_file = [
        {
          path = envFile;
          format = "raw";
        }
      ];
      environment = {
        MCP_TRANSPORT = "http";
        MCP_HOST = "0.0.0.0";
        MCP_PORT = port;
        TELEGRAM_SESSION_NAME = "/state/${sessionName}";
        TELEGRAM_SESSION_STRING = "";
        TELEGRAM_ALLOWED_ROOTS = "/downloads";
        TELEGRAM_SERVER_ROOTS_ONLY = "1";
        TELEGRAM_TRANSCRIBE = "off";
        TELEGRAM_EXPOSED_TOOLS =
          "read-only"
          + lib.optionalString (cfg.writeTools != [ ]) "+${lib.concatStringsSep "," cfg.writeTools}";
      };
      volumes = [
        (bind sessionDirectory "/state")
        (bind cfg.downloadDirectory "/downloads")
      ];
    };
  };
in
{
  _class = "homeManager";

  options.modules.telegram-mcp = {
    enable = lib.mkEnableOption "a local Telegram MCP service in OrbStack";

    writeTools = lib.mkOption {
      type = lib.types.listOf lib.types.str;
      default = [ ];
      description = "Telegram MCP write tools exposed alongside the read-only tools.";
    };

    downloadDirectory = lib.mkOption {
      type = lib.types.str;
      default = "${dataDirectory}/downloads";
      readOnly = true;
      internal = true;
      description = "Host directory mounted at /downloads in the container.";
    };

    url = lib.mkOption {
      type = lib.types.str;
      default = "http://127.0.0.1:${port}/mcp";
      readOnly = true;
      internal = true;
      description = "Local Streamable HTTP endpoint for MCP clients.";
    };
  };

  config = lib.mkIf cfg.enable {
    assertions = [
      {
        assertion = pkgs.stdenv.hostPlatform.isDarwin;
        message = "Telegram MCP requires macOS with OrbStack.";
      }
    ];

    home.activation.checkTelegramMcp = lib.hm.dag.entryBefore [ "writeBoundary" ] ''
      if [[ ! -f ${lib.escapeShellArg sessionFile} ]]; then
        warnEcho ${lib.escapeShellArg "Telegram MCP session not found. Sign in on this Mac and put the session file at ${sessionFile}."}
      fi
      if [[ ! -f ${lib.escapeShellArg envFile} ]]; then
        warnEcho ${lib.escapeShellArg "Telegram MCP credentials not found. Put TELEGRAM_API_ID and TELEGRAM_API_HASH in ${envFile}."}
      fi
    '';

    # The bind mounts need writable user directories before the agent can start.
    home.activation.prepareTelegramMcp =
      lib.hm.dag.entryBetween [ "setupLaunchAgents" ] [ "writeBoundary" ]
        ''
          run ${lib.getExe' pkgs.coreutils "install"} -d -m 0700 -- \
            ${lib.escapeShellArgs [
              sessionDirectory
              cfg.downloadDirectory
            ]}
        '';

    xdg.configFile."nix-config/telegram-mcp/compose.yaml".source = compose;

    # Keep Docker startup out of switch; the login agent owns the foreground job.
    launchd.agents.telegram-mcp = {
      enable = true;
      config = {
        ProgramArguments = [
          "${orbstackBin}/docker"
          "--context"
          "orbstack"
          "compose"
          "--file"
          "${compose}"
          "up"
          "--no-build"
          "--exit-code-from"
          "telegram-mcp"
        ];
        EnvironmentVariables.PATH = "${orbstackBin}:/usr/local/bin:/usr/bin:/bin";
        KeepAlive.PathState.${envFile} = true;
        ThrottleInterval = 30;
        ProcessType = "Background";
        StandardOutPath = logFile;
        StandardErrorPath = logFile;
        Umask = 63;
      };
    };
  };
}
