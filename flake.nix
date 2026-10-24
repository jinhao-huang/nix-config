rec {
  description = "Jinhao macOS and Linux environments";

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
    homebrew-jinhao-huang = {
      url = "github:jinhao-huang/homebrew-tap";
      flake = false;
    };
    home-manager.url = "github:nix-community/home-manager/release-26.05";
    home-manager.inputs.nixpkgs.follows = "nixpkgs";

    # Selectively backport the Pi module until it reaches a Home Manager release.
    home-manager-unstable = {
      url = "github:nix-community/home-manager/master";
      flake = false;
    };

    host-local = {
      url = "path:./hosts/empty-local.nix";
      flake = false;
    };

    llm-agents.url = "github:numtide/llm-agents.nix";
    hermes-agent.url = "github:NousResearch/hermes-agent";

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
      homebrew-jinhao-huang,
      home-manager,
      home-manager-unstable,
      host-local,
      llm-agents,
      hermes-agent,
      oh-my-tmux,
      ...
    }:
    let
      hosts = import ./hosts {
        lib = nixpkgs.lib;
        local = import host-local;
      };
      supportedSystems = [
        "aarch64-darwin"
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
      homebrewTaps = {
        "homebrew/homebrew-core" = homebrew-core;
        "homebrew/homebrew-cask" = homebrew-cask;
        "steipete/homebrew-tap" = homebrew-steipete;
        "jinhao-huang/homebrew-tap" = homebrew-jinhao-huang;
      };
      mkDarwinConfiguration =
        darwinHost:
        nix-darwin.lib.darwinSystem {
          specialArgs = {
            inherit
              configurationRevision
              darwinHost
              homebrewTaps
              ;
            masPackage = (mkPkgs nixpkgs-unstable darwinHost.system).mas;
          };
          modules = [
            {
              nix.settings = nixConfig;
              nixpkgs.config = nixpkgsConfig;
              modules.tailscale.package = self.packages.${darwinHost.system}.tailscale;
            }
            ./profiles/system/darwin
            nix-homebrew.darwinModules.nix-homebrew
            home-manager.darwinModules.home-manager
            {
              home-manager.useGlobalPkgs = true;
              home-manager.useUserPackages = true;
              home-manager.users.${darwinHost.username} =
                { pkgs, ... }:
                let
                  system = pkgs.stdenv.hostPlatform.system;
                  selectedPackages = self.packages.${system};
                  agentPackages = llm-agents.packages.${system};
                in
                {
                  imports = [ ./profiles/home/darwin.nix ];

                  modules.proton-pass.package = selectedPackages.proton-pass-cli;
                  modules.typst.package = selectedPackages.typst;
                  modules.pi.defaults = darwinHost.pi;
                  services.hermes-agent = darwinHost.hermes;
                  programs = {
                    mise.package = selectedPackages.mise;
                    claude-code.package = agentPackages.claude-code;
                    antigravity-cli.package = agentPackages.gemini-cli;
                    opencode.package = agentPackages.opencode;
                    pi-coding-agent.package = agentPackages.pi;
                  };
                };

              home-manager.extraSpecialArgs = {
                homeManagerUnstable = home-manager-unstable;
                hermesAgent = hermes-agent;
                ohMyTmux = oh-my-tmux;
              };
            }
          ];
        };
    in
    {
      packages = forAllSystems (
        system:
        let
          pkgs = mkPkgs nixpkgs system;
          unstablePkgs = mkPkgs nixpkgs-unstable system;
          configurationReference = pkgs.callPackage ./packages/configuration-reference {
            inherit home-manager;
          };
        in
        {
          deploy = pkgs.callPackage ./packages/deploy { nix = pkgs.lixPackageSets.stable.lix; };
          mise = unstablePkgs.mise;
          proton-pass-cli = unstablePkgs.proton-pass-cli;
          tailscale = unstablePkgs.tailscale;
          typst = unstablePkgs.typst;
          configuration-reference = configurationReference;
          update-configuration-reference = configurationReference.update;
        }
      );

      # Build Darwin profiles using:
      # $ darwin-rebuild build --flake .#laptop
      # $ darwin-rebuild build --flake .#desktop
      darwinConfigurations = nixpkgs.lib.mapAttrs (_: mkDarwinConfiguration) hosts.darwin;

      homeConfigurations = nixpkgs.lib.mapAttrs (
        _: host:
        home-manager.lib.homeManagerConfiguration {
          pkgs = mkPkgs nixpkgs host.system;
          extraSpecialArgs = {
            homeManagerUnstable = home-manager-unstable;
            hermesAgent = hermes-agent;
            ohMyTmux = oh-my-tmux;
          };
          modules = [
            ./profiles/home/linux.nix
            {
              home.username = host.username;
              home.homeDirectory = host.homeDirectory;
              home.file.".ssh/authorized_keys".text = nixpkgs.lib.concatMapStrings (
                file: builtins.readFile file + "\n"
              ) host.authorizedKeyFiles;
              modules.pi.defaults = host.pi;
              services.hermes-agent = host.hermes;
              modules.tailscale.package = self.packages.${host.system}.tailscale;
              programs.mise.package = self.packages.${host.system}.mise;
              programs.pi-coding-agent.package = llm-agents.packages.${host.system}.pi;
              modules.deepseek-harness = {
                package = llm-agents.packages.${host.system}.dsh;
                service = {
                  inherit (host.deepseekHarness) publicHost port proxyPort;
                };
              };
              modules.tailscale.serve.httpsPort = host.deepseekHarness.httpsPort;
              modules.sing-box = host.singBox;
            }
          ];
        }
      ) hosts.linux;

      checks = forAllSystems (
        system:
        {
          configuration-reference = self.packages.${system}.configuration-reference.tests.up-to-date;
          ai-agent-skills = (mkPkgs nixpkgs system).callPackage ./modules/ai-agents/checks { };
          hermes-runtime = (mkPkgs nixpkgs system).callPackage ./modules/hermes/tests.nix {
            hermesAgent = hermes-agent;
          };
        }
        // nixpkgs.lib.mapAttrs' (
          name: _: nixpkgs.lib.nameValuePair "${name}-home" self.homeConfigurations.${name}.activationPackage
        ) (nixpkgs.lib.filterAttrs (_: host: host.system == system) hosts.linux)
      );
    };
}
