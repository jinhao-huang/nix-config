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
}
