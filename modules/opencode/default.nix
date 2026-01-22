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

    xdg.configFile."opencode/config.json.tpl".text = builtins.toJSON {
      plugin = [ "opencode-gemini-auth" ];
      mcp = {
        context7 = {
          type = "local";
          command = [
            "npx"
            "-y"
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
          "git status*" = "allow";
          "git log*" = "allow";
          "git diff*" = "allow";
          "git show*" = "allow";
          "git branch*" = "allow";
          "git commit*" = "deny";
          "git push*" = "deny";
        };
      };
    };

    home.activation.injectOpencodeConfig = lib.hm.dag.entryAfter [ "writeBoundary" ] ''
      if [ -z "$DRY_RUN_CMD" ]; then
        if command -v op >/dev/null; then
           target="${config.xdg.configHome}/opencode/config.json"
           tpl="${config.xdg.configHome}/opencode/config.json.tpl"

           # Remove existing config if it's a symlink (managed by HM) or file
           rm -f "$target"

           # Inject secrets
           # Note: This requires 'op' to be authenticated
           echo "Injecting secrets into opencode/config.json..."
           op inject -i "$tpl" -o "$target"

           # Set permissions to read-only (400) to prevent accidental manual edits
           # and protect the secrets
           chmod 400 "$target"
        else
           echo "Warning: 'op' command not found. Cannot inject secrets."
        fi
      fi
    '';
  };
}
