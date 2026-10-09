{ ... }:

{
  programs.gh = {
    enable = true;
    settings.git_protocol = "ssh";

    # Git remotes use SSH; credentials are managed separately.
    gitCredentialHelper.enable = false;
  };
}
