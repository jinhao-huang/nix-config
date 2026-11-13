{ sshKeys }:
let
  common = {
    system = "aarch64-darwin";
    username = "jinhaohuang";
    homeDirectory = "/Users/jinhaohuang";
    authorizedKeyFiles = [ sshKeys.personal ];
    hermes = {
      enable = false;
      gateway.enable = false;
    };
  };
in
{
  laptop = common // {
    homebrew.casks = [
      "pixcake"
      "telegram"
      "tencent-meeting"
      "wechat"
    ];
    pi = { };
  };
  desktop = common // {
    tailnetHost = (import ../modules/ssh/inventory.nix).mac-mini.settings.HostName;
    hermes = common.hermes // {
      enable = true;
      backend.mode = "dashboard";
    };
    homebrew.casks = [
      "airbuddy"
      "betterdisplay"
    ];
    pi = { };
  };
}
