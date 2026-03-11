# ── ThinkPad P15 Wiring ─────────────────────────────────────
# Dieses flake-parts Modul erstellt nixosConfigurations.thinkpad-p15
# aus den bestehenden NixOS- und Home-Manager-Modulen.
{ inputs, ... }:
let
  inherit (inputs) nixpkgs home-manager sops-nix;
in
{
  flake.nixosConfigurations.thinkpad-p15 = nixpkgs.lib.nixosSystem {
    system = "x86_64-linux";
    specialArgs = { inherit inputs; };  # TODO: In Phase C-5 entfernen
    modules = [
      ../hosts/thinkpad-p15
      ../modules/common
      ../modules/desktop

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
