let
  identities = {
    personal.publicKey = ./public-keys/personal.pub;
    cas.publicKey = ./public-keys/cas.pub;
  };
in
{
  aliyun-ecs = {
    settings = {
      HostName = "aliyun-ecs.bison-agama.ts.net";
      User = "jinhaohuang";
      Port = 22;
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

  fn-evo2 = {
    settings = {
      HostName = "fn-evo2.bison-agama.ts.net";
      User = "jinhaohuang";
      Port = 22;
    };
  };

  mac-mini = {
    settings = {
      HostName = "mac-mini.bison-agama.ts.net";
      User = "jinhaohuang";
      Port = 22;
    };
  };

  macbook-air = {
    settings = {
      HostName = "macbook-air.bison-agama.ts.net";
      User = "jinhaohuang";
      Port = 22;
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

  zouter-hk = {
    identity = identities.personal;

    settings = {
      HostName = "zouter-hk.internal";
      User = "jinhaohuang";
      Port = 63872;
    };
  };

  zouter-slc = {
    identity = identities.personal;

    settings = {
      HostName = "zouter-slc.internal";
      User = "jinhaohuang";
      Port = 61120;
    };
  };
}
