# ── Server-Netzwerk ─────────────────────────────────────────
{ ... }:
{
  imports = [
    ./static-ip.nix
    ./caddy.nix
    ./netbird.nix
    ./dns.nix
  ];
}
