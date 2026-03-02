# ── Server-Netzwerk ─────────────────────────────────────────
{ ... }:
{
  imports = [
    ./static-ip.nix
    ./caddy.nix
    # ./netbird.nix    # SPÄTER — erst wenn VPN-Zugang verfügbar ist
  ];
}
