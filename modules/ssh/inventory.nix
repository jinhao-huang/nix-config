{
  aliyun-ecs = {
    reference = "pass://Dev/Aliyun-ECS/public_key";

    hosts."Aliyun-ECS" = {
      hostname = "aliyun.internal";
      user = "jinhaohuang";
      port = 29360;
      remoteForwards = [
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
