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
    hermesServe = {
      host = (import ../modules/ssh/inventory.nix).mac-mini.settings.HostName;
      loginRef = "pass://Dev/Hermes Dashboard";
    };
    hermes = common.hermes // {
      enable = true;
      backend.mode = "dashboard";
      settings.model = {
        provider = "minimax-cn";
        default = "MiniMax-M3.1-Flash";
      };
    };
    hermesProtonPass = {
      DEEPSEEK_API_KEY = "pass://Dev/DeepSeek/API Key";
      MINIMAX_CN_API_KEY = "pass://Dev/MiniMax CN/Subscription Key";
    };
    homebrew.casks = [
      "airbuddy"
      "betterdisplay"
    ];
    pi = { };
  };
}
