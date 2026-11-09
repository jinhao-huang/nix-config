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
      passwordRef = "pass://Dev/Hermes Dashboard/password";
    };
    hermes = common.hermes // {
      enable = true;
      backend.mode = "dashboard";
      settings.model = {
        provider = "deepseek";
        default = "deepseek-flash";
      };
    };
    hermesProtonPass.DEEPSEEK_API_KEY = "pass://Dev/DeepSeek/API Key";
    homebrew.casks = [
      "airbuddy"
      "betterdisplay"
    ];
    pi = { };
  };
}
