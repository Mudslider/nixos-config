# ── Homeserver Wiring (ASRock N100DC-ITX) ───────────────────
# Dieses flake-parts Modul erstellt nixosConfigurations.homeserver
# aus den bestehenden NixOS- und Home-Manager-Modulen.
{ inputs, ... }:
let
  inherit (inputs) nixpkgs home-manager sops-nix disko autoaspm;
in
{
  flake.nixosConfigurations.homeserver = nixpkgs.lib.nixosSystem {
    system = "x86_64-linux";
    specialArgs = { inherit inputs; };  # TODO: In Phase C-5 entfernen
    modules = [
      ../hosts/homeserver
      ../modules/common
      ../modules/server

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
