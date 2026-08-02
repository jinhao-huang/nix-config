{
  aliyun-ecs = {
    reference = "pass://Dev/Aliyun-ECS/public_key";

    hosts."Aliyun-ECS" = {
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
    reference = "pass://Dev/ISCAS-r750xa/public_key";

    hosts."iscas-r750xa" = {
      HostName = "iscas-r750xa.internal";
      User = "huangjh";
      Port = 22;
    };
  };
}
