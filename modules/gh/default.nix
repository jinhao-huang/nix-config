{ ... }:

{
  programs.gh = {
    enable = true;
    settings.git_protocol = "ssh";

    # Git remotes use SSH through the Proton Pass agent.
    gitCredentialHelper.enable = false;
  };
}
