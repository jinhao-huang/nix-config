{ sshKeys }:
let
  common = {
    system = "aarch64-darwin";
    username = "jinhaohuang";
    homeDirectory = "/Users/jinhaohuang";
    authorizedKeyFiles = [ sshKeys.personal ];
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
    homebrew.casks = [
      "airbuddy"
      "betterdisplay"
    ];
    pi = { };
  };
}
