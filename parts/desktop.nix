# ── Desktop-Module (nur Laptop/Workstation) ─────────────────
# Wraps das gesamte modules/desktop/ Verzeichnis als deferredModule.
{ ... }:
{
  nixosModules.desktop = import ../modules/desktop;
}
