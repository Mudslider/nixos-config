# ── Homeserver Wiring (ASRock N100DC-ITX) ───────────────────
{ config, inputs, ... }:
let
  inherit (inputs) nixpkgs home-manager sops-nix disko autoaspm;
in
{
  flake.nixosConfigurations.homeserver = nixpkgs.lib.nixosSystem {
    system = "x86_64-linux";
    specialArgs = { inherit inputs; };
    modules = [
      config.nixosModules.common
      config.nixosModules.server
      ../hosts/homeserver

      disko.nixosModules.disko
      sops-nix.nixosModules.sops
      autoaspm.nixosModules.default

      home-manager.nixosModules.home-manager
      {
        home-manager = {
          useGlobalPkgs = true;
          useUserPackages = true;
          users.philip = import ../home/server;
        };
      }
    ];
  };
}
