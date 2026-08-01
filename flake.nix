rec {
  description = "Jinhao nix-darwin system flake";

  nixConfig = {
    extra-substituters = [ "https://cache.numtide.com?priority=50" ];
    extra-trusted-public-keys = [
      "niks3.numtide.com-1:DTx8wZduET09hRmMtKdQDxNNthLQETkc/yaX7M4qK0g="
    ];
  };

  inputs = {
    nixpkgs.url = "github:NixOS/nixpkgs/nixos-26.05";
    nixpkgs-unstable.url = "github:NixOS/nixpkgs/nixpkgs-unstable";
    nix-darwin.url = "github:nix-darwin/nix-darwin/nix-darwin-26.05";
    nix-darwin.inputs.nixpkgs.follows = "nixpkgs";

    nix-homebrew.url = "github:zhaofengli/nix-homebrew";
    # Optional: Declarative tap management
    homebrew-core = {
      url = "github:homebrew/homebrew-core";
      flake = false;
    };
    homebrew-cask = {
      url = "github:homebrew/homebrew-cask";
      flake = false;
    };
    homebrew-steipete = {
      url = "github:steipete/homebrew-tap";
      flake = false;
    };
    home-manager.url = "github:nix-community/home-manager/release-26.05";
    home-manager.inputs.nixpkgs.follows = "nixpkgs";

    llm-agents.url = "github:numtide/llm-agents.nix";

    oh-my-tmux = {
      url = "github:gpakosz/.tmux";
      flake = false;
    };
  };

  outputs =
    {
      self,
      nix-darwin,
      nixpkgs,
      nixpkgs-unstable,
      nix-homebrew,
      homebrew-core,
      homebrew-cask,
      homebrew-steipete,
      home-manager,
      llm-agents,
      oh-my-tmux,
      ...
    }:
    let
      darwinHost = {
        system = "aarch64-darwin";
        username = "jinhaohuang";
        homeDirectory = "/Users/jinhaohuang";
      };
      supportedSystems = [
        "aarch64-darwin"
        "x86_64-darwin"
        "aarch64-linux"
        "x86_64-linux"
      ];
      forAllSystems = nixpkgs.lib.genAttrs supportedSystems;
      nixpkgsConfig = {
        allowUnfree = true;
      };
      mkPkgs =
        source: system:
        import source {
          inherit system;
          config = nixpkgsConfig;
        };
      configurationRevision = self.rev or self.dirtyRev or null;
      customPackages = self.packages.${darwinHost.system};
      homebrewTaps = {
        "homebrew/homebrew-core" = homebrew-core;
        "homebrew/homebrew-cask" = homebrew-cask;
        "steipete/homebrew-tap" = homebrew-steipete;
      };
      llmAgentPackages = llm-agents.packages.${darwinHost.system};
      masPackage = (mkPkgs nixpkgs-unstable darwinHost.system).mas;
    in
    {
      packages = forAllSystems (
        system:
        let
          pkgs = mkPkgs nixpkgs system;
        in
        {
          mise = import ./packages/mise { inherit pkgs; };
          proton-pass-cli = import ./packages/proton-pass-cli { inherit pkgs; };
        }
      );

      # Build darwin flake using:
      # $ darwin-rebuild build --flake .#mac
      darwinConfigurations."mac" = nix-darwin.lib.darwinSystem {
        specialArgs = {
          inherit
            configurationRevision
            darwinHost
            homebrewTaps
            masPackage
            ;
        };
        modules = [
          (
            { config, ... }:
            {
              homebrew.taps = builtins.attrNames config.nix-homebrew.taps;
              nix.settings = nixConfig;
              nixpkgs.config = nixpkgsConfig;
            }
          )
          ./modules/darwin/default.nix
          nix-homebrew.darwinModules.nix-homebrew
          home-manager.darwinModules.home-manager
          {
            home-manager.useGlobalPkgs = true;
            home-manager.useUserPackages = true;
            home-manager.users.${darwinHost.username} = ./home.nix;

            home-manager.extraSpecialArgs = {
              inherit customPackages darwinHost llmAgentPackages;
              ohMyTmux = oh-my-tmux;
            };
          }
        ];
      };

      homeConfigurations."linux-deployment" = home-manager.lib.homeManagerConfiguration {
        pkgs = mkPkgs nixpkgs "x86_64-linux";

        # Pass the new deployment.nix file to the modules
        modules = [ ./deployment.nix ];
      };
    };
}
