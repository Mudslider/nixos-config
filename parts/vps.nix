# ── Hetzner VPS Wiring (öffentlicher Eingangsknoten) ────────
# Reverse Proxy mit Let's Encrypt → Homeserver via NetBird
{ config, inputs, ... }:
let
  inherit (inputs) nixpkgs sops-nix disko;
in
{
  flake.nixosConfigurations.vps = nixpkgs.lib.nixosSystem {
    system = "x86_64-linux";
    modules = [
      config.nixosModules.common
      ../hosts/vps

      disko.nixosModules.disko
      sops-nix.nixosModules.sops
    ];
  };
}
