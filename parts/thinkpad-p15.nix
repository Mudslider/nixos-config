# ── ThinkPad P15 Wiring ─────────────────────────────────────
{ config, inputs, ... }:
let
  inherit (inputs) nixpkgs home-manager sops-nix;
in
{
  flake.nixosConfigurations.thinkpad-p15 = nixpkgs.lib.nixosSystem {
    system = "x86_64-linux";
    specialArgs = { inherit inputs; };
    modules = [
      config.nixosModules.common
      config.nixosModules.desktop
      ../hosts/thinkpad-p15

      sops-nix.nixosModules.sops

      home-manager.nixosModules.home-manager
      {
        home-manager = {
          useGlobalPkgs = true;
          useUserPackages = true;
          users.polly = import ../home/laptop;
        };
      }
    ];
  };
}
