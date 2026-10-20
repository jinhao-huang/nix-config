let
  common = {
    system = "aarch64-darwin";
    username = "jinhaohuang";
    homeDirectory = "/Users/jinhaohuang";
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
