{
  description = "NixOS — Unified Config (Homeserver + ThinkPad P15)";

  inputs = {
    nixpkgs.url = "github:NixOS/nixpkgs/nixos-unstable";

    home-manager = {
      url = "github:nix-community/home-manager";
      inputs.nixpkgs.follows = "nixpkgs";
    };

    sops-nix = {
      url = "github:Mic92/sops-nix";
      inputs.nixpkgs.follows = "nixpkgs";
    };

    disko = {
      url = "github:nix-community/disko";
      inputs.nixpkgs.follows = "nixpkgs";
    };

    autoaspm = {
      url = "git+https://git.notthebe.ee/notthebee/AutoASPM";
      inputs.nixpkgs.follows = "nixpkgs";
    };
  };

  outputs = inputs@{ self, nixpkgs, home-manager, sops-nix, disko, autoaspm, ... }:
  {
    # ── Maschine 1: Homeserver (ASRock N100DC-ITX) ──────────
    nixosConfigurations.homeserver = nixpkgs.lib.nixosSystem {
      system = "x86_64-linux";
      specialArgs = { inherit inputs; };
      modules = [
        ./hosts/homeserver
        ./modules/common
        ./modules/server

        disko.nixosModules.disko
        sops-nix.nixosModules.sops
        autoaspm.nixosModules.default

        home-manager.nixosModules.home-manager
        {
          home-manager = {
            useGlobalPkgs = true;
            useUserPackages = true;
            users.philip = import ./home/server;
          };
        }
      ];
    };

    # ── Maschine 2: ThinkPad P15 ───────────────────────────
    nixosConfigurations.thinkpad-p15 = nixpkgs.lib.nixosSystem {
      system = "x86_64-linux";
      specialArgs = { inherit inputs; };
      modules = [
        ./hosts/thinkpad-p15
        ./modules/common
        ./modules/desktop

        sops-nix.nixosModules.sops

        home-manager.nixosModules.home-manager
        {
          home-manager = {
            useGlobalPkgs = true;
            useUserPackages = true;
            users.polly = import ./home/laptop;
          };
        }
      ];
    };
  };
}
