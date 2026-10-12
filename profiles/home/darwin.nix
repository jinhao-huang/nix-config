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
    ../../modules/codex
    ../../modules/opencode
    ../../modules/pi
    ../../modules/ai-agents
    ../../modules/zed
    ../../modules/mise
    ../../modules/typst
    ../../modules/ghostty
  ];

  home.stateVersion = "25.05";
  home.packages = [ pkgs.lima ];

  modules.claude-code.enable = true;
  modules.proton-pass.enable = true;
  modules.ssh.includeHosts = true;
  modules.ssh.agentSocket = config.modules.proton-pass.sshAgentSocket;
  modules.go.enable = true;
  modules.rust.enable = true;
  modules.gemini-cli.enable = true;
  modules.codex.enable = true;
  modules.opencode.enable = false;
  modules.pi.enable = true;
  modules.ai-agents.enable = true;
  modules.zed.enable = true;
  modules.mise.enable = true;
  modules.typst.enable = true;

  modules.ai-agents.repoRelativePath = "nix-config";
  programs.gpg.enable = true;
}
