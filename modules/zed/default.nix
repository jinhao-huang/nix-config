{
  config,
  lib,
  ...
}:

let
  cfg = config.modules.zed;
in
{
  options.modules.zed.enable = lib.mkEnableOption "Zed configuration";

  config = lib.mkIf cfg.enable {
    programs.zed-editor = {
      enable = true;
      package = null;
      mutableUserSettings = false;
      mutableUserKeymaps = false;

      userSettings = {
        agent_servers.opencode.type = "registry";
        cli_default_open_behavior = "new_window";

        project_panel.dock = "left";

        agent = {
          sidebar_side = "right";
          dock = "right";
          default_profile = "write";
          default_model = {
            provider = "copilot_chat";
            model = "gpt-5-mini";
          };
          favorite_models = [ ];
          model_parameters = [ ];
        };

        git_panel = {
          dock = "left";
          tree_view = true;
        };

        git.inline_blame = {
          enabled = false;
          show_commit_summary = false;
        };

        vim_mode = true;
        soft_wrap = "editor_width";
        autosave = "on_focus_change";
        session.trust_all_worktrees = false;

        languages = {
          Nix.language_servers = [
            "nixd"
            "!nil"
          ];
          TSX.formatter.language_server.name = "prettier";
        };
      };

      userKeymaps = [
        {
          context = "Workspace";
          bindings."cmd-shift-g" = "git_panel::ToggleFocus";
        }
        {
          context = "AgentPanel";
          bindings."alt-cmd-n" = "agent::ToggleNewThreadMenu";
        }
        {
          context = "Workspace";
          bindings."cmd-shift-t" = "terminal_panel::ToggleFocus";
        }
        {
          context = "!ContextEditor > (Editor && mode == full)";
          bindings."cmd-i" = "assistant::InlineAssist";
        }
        {
          context = "Terminal";
          bindings."cmd-i" = "assistant::InlineAssist";
        }
        {
          context = "ContextEditor > Editor";
          bindings."cmd-shift-g" = "git_panel::ToggleFocus";
        }
        {
          context = "Pane";
          bindings."cmd-shift-g" = "git_panel::ToggleFocus";
        }
      ];
    };
  };
}
