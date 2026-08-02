let
  identities = {
    personal.publicKey = ./public-keys/personal.pub;
    cas.publicKey = ./public-keys/cas.pub;
  };
in
{
  aliyun-ecs = {
    identity = identities.personal;

    settings = {
      HostName = "aliyun.internal";
      User = "jinhaohuang";
      Port = 29360;
      RemoteForward = [
        {
          bind.port = 6152;
          host = {
            address = "localhost";
            port = 6152;
          };
        }
        {
          bind.port = 6153;
          host = {
            address = "localhost";
            port = 6153;
          };
        }
      ];
    };
  };

  iscas-r750xa = {
    identity = identities.cas;

    settings = {
      HostName = "iscas-r750xa.internal";
      User = "huangjh";
      Port = 22;
    };
  };
}
