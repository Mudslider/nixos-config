# ── Server-Module (nur Homeserver) ──────────────────────────
# Wraps das gesamte modules/server/ Verzeichnis als deferredModule.
# Die interne Struktur (hardware, networking, security, services, storage)
# bleibt unverändert — import-Hubs und Einzelmodule funktionieren wie bisher.
{ ... }:
{
  nixosModules.server = import ../modules/server;
}
