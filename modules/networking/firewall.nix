# ── Firewall ─────────────────────────────────────────────────────
{ ... }:
{
  networking.firewall = {
    enable = true;

    # Vaultwarden – uncomment if you need remote access.
    # allowedTCPPorts = [ 8000 ];

    # KDE Connect – uncomment if you use it.
    # allowedTCPPortRanges = [{ from = 1714; to = 1764; }];
    # allowedUDPPortRanges = [{ from = 1714; to = 1764; }];
  };
}
