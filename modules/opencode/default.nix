{
  config,
  pkgs,
  lib,
  inputs,
  ...
}:

let
  cfg = config.modules.opencode;
  system = pkgs.stdenv.hostPlatform.system;
  protonPassCli = config.modules.proton-pass.package;
  jsonFormat = pkgs.formats.json { };
  smallModel = "minimax-cn-coding-plan/MiniMax-M3";

  settings = {
    small_model = smallModel;
    mcp = {
      context7 = {
        type = "local";
        command = [
          "mise"
          "exec"
          "node@24"
          "pnpm@11"
          "--"
          "pnpm"
          "dlx"
          "@upstash/context7-mcp@3.2.3"
          "--api-key"
          "{{ pass://Dev/Context7-API Key/OpenCode }}"
        ];
        enabled = true;
      };
    };
    permission = {
      bash = {
        "*" = "ask";
        "ls *" = "allow";
        "grep *" = "allow";
        "cat *" = "allow";
        "find *" = "allow";
        "pwd *" = "allow";
        "echo *" = "allow";
        "head *" = "allow";
        "tail *" = "allow";
        "git status*" = "allow";
        "git log*" = "allow";
        "git diff*" = "allow";
        "git show*" = "allow";
        "git branch*" = "allow";
        "git commit*" = "ask";
        "git push*" = "ask";
      };
    };
    agent = {
      commit = {
        model = smallModel;
      };
      explain = {
        model = smallModel;
      };
      explore = {
        model = smallModel;
      };
    };
  };

  tuiSettings = {
    "$schema" = "https://opencode.ai/tui.json";
    scroll_acceleration = {
      enabled = true;
    };
  };

  configFileTpl = jsonFormat.generate "opencode-config.json.tpl" settings;
  tuiConfigFile = jsonFormat.generate "opencode-tui.json" tuiSettings;
in
{
  options.modules.opencode = {
    enable = lib.mkEnableOption "opencode";
  };

  config = lib.mkIf cfg.enable {
    programs.opencode = {
      enable = true;
      package = inputs.llm-agents.packages.${system}.opencode;
    };

    xdg.configFile."opencode/tui.json".source = tuiConfigFile;

    home.activation.injectOpencodeConfig = lib.hm.dag.entryAfter [ "writeBoundary" ] ''
      if [ -z "$DRY_RUN_CMD" ]; then
        PASS_CMD="${protonPassCli}/bin/pass-cli"
        target="${config.xdg.configHome}/opencode/opencode.json"
        legacy_target="${config.xdg.configHome}/opencode/config.json"
        tpl="${configFileTpl}"

        if "$PASS_CMD" test >/dev/null 2>&1; then
          (
            umask 077
            tmp="$(${pkgs.coreutils}/bin/mktemp "$target.tmp.XXXXXX")"
            trap '[ -z "$tmp" ] || ${pkgs.coreutils}/bin/rm -f "$tmp"' EXIT INT TERM

            echo "Injecting Proton Pass secrets into opencode/opencode.json..."
            if "$PASS_CMD" inject \
              --in-file "$tpl" \
              --out-file "$tmp" \
              --force \
              --file-mode 0400 \
              && ${pkgs.jq}/bin/jq -e . "$tmp" >/dev/null \
              && ! ${pkgs.gnugrep}/bin/grep -q '{{[[:space:]]*pass://' "$tmp"; then
              ${pkgs.coreutils}/bin/mv -f "$tmp" "$target"
              ${pkgs.coreutils}/bin/rm -f "$legacy_target"
              tmp=""
            else
              echo "Warning: Proton Pass injection failed; preserving the existing OpenCode configuration." >&2
            fi
          )
        else
          echo "Warning: Proton Pass is not logged in; preserving the existing OpenCode configuration." >&2
        fi
      fi
    '';
  };
}
