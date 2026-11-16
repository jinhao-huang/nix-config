checkout:
{
  config,
  lib,
  pkgs,
  ...
}:
let
  skillDir = "${checkout}/skills/music-library";
  dataDir = "${config.xdg.dataHome}/metaweave";
  telegramState = "${dataDir}/telegram";
  downloads = "${dataDir}/downloads";
  envFile = "${config.xdg.configHome}/nix-config/telegram-mcp.env";
  port = "8765";
  orbstackBin = "/Applications/OrbStack.app/Contents/MacOS/xbin";
  logFile = "${config.home.homeDirectory}/Library/Logs/telegram-music.log";
  bind = source: target: {
    type = "bind";
    inherit source target;
    bind.create_host_path = false;
  };
  writeTools = [
    "send_message"
    "press_inline_button"
    "download_media"
  ];
  readOnlyTools = [
    "get_chat"
    "get_history"
    "get_messages"
    "list_inline_buttons"
  ];
  compose = (pkgs.formats.json { }).generate "telegram-music-compose.json" {
    name = "telegram-music";
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
        TELEGRAM_SESSION_NAME = "/state/telegram";
        TELEGRAM_SESSION_STRING = "";
        TELEGRAM_ALLOWED_ROOTS = "/downloads";
        TELEGRAM_SERVER_ROOTS_ONLY = "1";
        TELEGRAM_TRANSCRIBE = "off";
        TELEGRAM_EXPOSED_TOOLS = "read-only+${lib.concatStringsSep "," writeTools}";
      };
      volumes = [
        (bind telegramState "/state")
        (bind downloads "/downloads")
      ];
    };
  };
in
{
  modules.ai-agents.externalSkills.music-library = skillDir;

  home.activation.checkMusicLibrary = lib.hm.dag.entryBefore [ "writeBoundary" ] ''
    if [[ ! -f ${lib.escapeShellArg "${skillDir}/SKILL.md"} ]]; then
      warnEcho ${lib.escapeShellArg "Metaweave skill not found. Clone Metaweave into ${checkout} before using music-library."}
    fi
    if [[ ! -f ${lib.escapeShellArg envFile} ]]; then
      warnEcho ${lib.escapeShellArg "Telegram MCP credentials not found. Put TELEGRAM_API_ID and TELEGRAM_API_HASH in ${envFile}."}
    fi
  '';

  # The bind mounts need writable user directories before the agent can start.
  home.activation.prepareMusicLibrary =
    lib.hm.dag.entryBetween [ "setupLaunchAgents" ] [ "writeBoundary" ]
      ''
        run ${lib.getExe' pkgs.coreutils "install"} -d -m 0700 -- \
          ${lib.escapeShellArgs [
            telegramState
            downloads
          ]}
      '';

  services.hermes-agent = {
    environment.METAWEAVE_DOWNLOADS = downloads;
    settings.mcp_servers.telegram-music = {
      url = "http://127.0.0.1:${port}/mcp";
      connect_timeout = 5;
      timeout = 600;
      tools = {
        include = writeTools ++ readOnlyTools;
        prompts = false;
        resources = false;
      };
    };
  };

  xdg.configFile."nix-config/telegram-mcp/compose.yaml".source = compose;

  # Keep Docker startup out of switch; the login agent owns the foreground job.
  launchd.agents.telegram-music = {
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
}
