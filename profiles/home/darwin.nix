{ config, pkgs, ... }:
{
  imports = [
    ./common.nix
    ../../modules/fonts
    ../../modules/proton-pass
    ../../modules/go
    ../../modules/rust
    ../../modules/claude-code
    ../../modules/gemini-cli
    ../../modules/opencode
    ../../modules/pi
    ../../modules/deepseek-harness
    ../../modules/ai-agents
    ../../modules/zed
    ../../modules/mise
    ../../modules/typst
    ../../modules/ghostty
  ];

  home.stateVersion = "25.05";
  home.packages = [ pkgs.lima ];
  home.sessionPath = [ "/Applications/ChatGPT.app/Contents/Resources/codex-cli/bin" ];

  modules.claude-code.enable = false;
  modules.proton-pass.enable = true;
  modules.ssh.includeHosts = true;
  modules.ssh.agentSocket = config.modules.proton-pass.sshAgentSocket;
  modules.go.enable = true;
  modules.rust.enable = true;
  modules.gemini-cli.enable = false;
  modules.opencode.enable = false;
  modules.pi = {
    enable = true;
    # Surge Enhanced Mode resolves proxied domains into this fake-IP range.
    webSearch.allowRanges = [ "198.18.0.0/15" ];
  };
  modules.deepseek-harness.enable = true;
  modules.ai-agents = {
    enable = true;
    repoRelativePath = "nix-config";
    environment = ''
      ## Local Execution Environment

      - Network access on this Mac is normally handled by Surge. Run commands normally; inspect the active takeover and routing state if access fails.
      - For Surge operations or network diagnosis on this Mac, read `~/.agents/skills/surge/SKILL.md` and use `surge-cli`.
    '';
  };
  modules.zed.enable = true;
  modules.mise.enable = true;
  modules.typst.enable = true;

  programs.gpg.enable = true;
}
