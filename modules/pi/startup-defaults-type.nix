{ lib }:
lib.types.submodule {
  options = {
    model = lib.mkOption {
      type = lib.types.nullOr (
        lib.types.submodule {
          options = {
            provider = lib.mkOption {
              type = lib.types.nonEmptyStr;
              description = "Pi provider identifier.";
            };
            id = lib.mkOption {
              type = lib.types.nonEmptyStr;
              description = "Model identifier within the provider.";
            };
          };
        }
      );
      default = null;
      description = "Default provider and model for new sessions; null lets Pi select them.";
    };
    thinkingLevel = lib.mkOption {
      type = lib.types.nullOr (
        lib.types.enum [
          "off"
          "minimal"
          "low"
          "medium"
          "high"
          "xhigh"
          "max"
        ]
      );
      default = null;
      description = "Default thinking level for new sessions; null uses Pi's default.";
    };
  };
}
