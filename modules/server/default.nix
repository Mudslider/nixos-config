# ── Server-Module (nur Homeserver) ──────────────────────────
{ ... }:
{
  imports = [
    ./hardware
    ./networking
    ./security
    ./storage
    ./services
  ];
}
