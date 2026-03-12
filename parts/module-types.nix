# ── Modul-Typen ─────────────────────────────────────────────
# Definiert die Options, über die Feature-Dateien NixOS-Config
# beitragen. Typ deferredModule erlaubt Merging aus mehreren Dateien.
#
# Beispiel: locale.nix und nix-settings.nix setzen beide
# nixosModules.common → wird automatisch zusammengeführt.
# Das Wiring-Modul (homeserver.nix) gibt das Ergebnis an nixosSystem.
{ lib, ... }:
{
  options.nixosModules = lib.mkOption {
    type = lib.types.attrsOf lib.types.deferredModule;
    default = {};
    description = "Geteilte NixOS-Module, zusammengesetzt in den Wiring-Dateien";
  };
}
