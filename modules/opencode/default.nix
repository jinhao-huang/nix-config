{
  config,
  pkgs,
  pkgs-unstable,
  lib,
  ...
}:

with lib;

let
  cfg = config.modules.opencode;

  settings = {
    plugin = [ "opencode-gemini-auth" ];
    mcp = {
      context7 = {
        type = "local";
        command = [
          "mise"
          "exec"
          "pnpm"
          "--"
          "pnpm"
          "dlx"
          "@upstash/context7-mcp"
          "--api-key"
          "{{ op://Dev/Context7-OpenCode/credential }}"
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
        "git commit*" = "deny";
        "git push*" = "deny";
      };
    };
    agent = {
      free = {
        permission = "allow";
      };
    };
  };

  configFileTpl =
    pkgs.runCommand "config.json.tpl"
      {
        nativeBuildInputs = [ pkgs.jq ];
        jsonContent = builtins.toJSON settings;
      }
      ''
        echo "$jsonContent" | jq '.' > $out
      '';
in
{
  options.modules.opencode = {
    enable = mkEnableOption "opencode";
  };

  config = mkIf cfg.enable {
    programs.opencode = {
      enable = true;
      package = pkgs-unstable.opencode;
    };

    xdg.configFile."opencode/config.json.tpl".source = configFileTpl;

    home.activation.injectOpencodeConfig = lib.hm.dag.entryAfter [ "writeBoundary" ] ''
      if [ -z "$DRY_RUN_CMD" ]; then
        OP_CMD="${pkgs._1password-cli}/bin/op"

        if [ -x "$OP_CMD" ]; then
           target="${config.xdg.configHome}/opencode/config.json"
           tpl="${configFileTpl}"

           if [ -e "$target" ]; then
             chmod u+w "$target" || true
             rm -f "$target"
           fi

           # Inject secrets
           # Note: This requires 'op' to be authenticated
           echo "Injecting secrets into opencode/config.json using $OP_CMD..."
           "$OP_CMD" inject -i "$tpl" -o "$target"

           # Set permissions to read-only (400) to prevent accidental manual edits
           # and protect the secrets
           chmod 400 "$target"
        else
           echo "Warning: 'op' command not found at $OP_CMD. Cannot inject secrets."
        fi
      fi
    '';
  };
}
