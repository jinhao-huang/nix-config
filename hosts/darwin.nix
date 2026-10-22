let
  common = {
    system = "aarch64-darwin";
    username = "jinhaohuang";
    homeDirectory = "/Users/jinhaohuang";
    authorizedKeyFiles = [ ../modules/ssh/public-keys/personal.pub ];
  };
in
{
  laptop = common // {
    pi = { };
  };
  desktop = common // {
    pi = { };
  };
}
