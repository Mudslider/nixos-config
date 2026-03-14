# ── Nix / Flake Einstellungen (beide Maschinen) ─────────────
{ ... }:
{
  nixosModules.common = {
    nix.settings = {
      experimental-features = [ "nix-command" "flakes" ];
      auto-optimise-store = true;
      trusted-users = [ "root" "@wheel" ];

      # Binary Caches für Community-Pakete (sops-nix, home-manager etc.)
      # Verhindert lokale Kompilierung von Paketen die nicht in cache.nixos.org sind
      substituters = [
        "https://cache.nixos.org"
        "https://nix-community.cachix.org"
      ];
      trusted-public-keys = [
        "cache.nixos.org-1:6NCHdD59X431o0gWypbMrAURkbJ16ZPMQFGspcDShjY="
        "nix-community.cachix.org-1:mB9FSh9qf2dCimDSUo8Zy7bkq5CX+/rkCWyvRCUSeBo="
      ];
    };

    nix.gc = {
      automatic = true;
      dates = "weekly";
      options = "--delete-older-than 30d";
    };

    nixpkgs.config.allowUnfree = true;
  };
}
