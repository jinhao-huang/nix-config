{
  checkout,
  nasHost,
  modelEnvironmentKeys,
}:
{
  config,
  lib,
  ...
}:
let
  hermesSettings = config.services.hermes-agent.settings;
  telegramMcp = config.modules.telegram-mcp;
  skillDir = "${checkout}/skills/music-library";
  readOnlyTools = [
    "get_chat"
    "get_history"
    "get_messages"
    "list_inline_buttons"
  ];
in
{
  home.activation.checkMusicLibrary = lib.hm.dag.entryBefore [ "writeBoundary" ] ''
    if [[ ! -f ${lib.escapeShellArg "${skillDir}/SKILL.md"} ]]; then
      warnEcho ${lib.escapeShellArg "Metaweave skill not found. Clone Metaweave into ${checkout} before using music-library."}
    fi
  '';

  modules.telegram-mcp = {
    dataDirectory = "${config.xdg.dataHome}/metaweave";
    writeTools = lib.mkBefore [
      "send_message"
      "press_inline_button"
    ];
  };

  modules.hermes.namedProfiles.music-library = {
    workingDirectory = telegramMcp.downloadDirectory;
    environmentKeys = modelEnvironmentKeys;
    soul = ''
      You manage the music library. Follow the music-library skill for its workflows and approvals.
      Use Simplified Chinese for all user-facing communication, including questions,
      progress updates, approval requests, and final replies.
      For unrelated requests, ask the user to switch to the default profile.
    '';
    settings = {
      inherit (hermesSettings)
        model
        providers
        security
        updates
        ;
      auth.adopt_external_logins = hermesSettings.auth.adopt_external_logins;
      agent = {
        inherit (hermesSettings.agent) coding_context reasoning_overrides;
        environment_hint = ''
          ${hermesSettings.agent.environment_hint}
          Use the Metaweave checkout at ${checkout} and its .venv on this Mac.
          For in-place library work, use SSH host ${nasHost}.
          Telegram MCP /downloads maps to ${telegramMcp.downloadDirectory} on this Mac.
        '';
      };
      terminal.backend = "local";
      skills = {
        external_dirs = [ skillDir ];
        write_approval = true;
      };
      platform_toolsets.cli = [
        "terminal"
        "file"
        "skills"
        "web"
        "browser"
        "memory"
        "clarify"
      ];
      mcp_servers.telegram-music = {
        inherit (telegramMcp) url;
        connect_timeout = 5;
        timeout = 600;
        tools = {
          include = telegramMcp.writeTools ++ readOnlyTools;
          prompts = false;
          resources = false;
        };
      };
    };
  };

}
