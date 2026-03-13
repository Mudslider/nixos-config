{ ... }:

{
  # ── Firewall (VPS — öffentlich erreichbar) ─────────────────
  networking.firewall = {
    enable = true;

    allowedTCPPorts = [
      22    # SSH
      80    # Caddy HTTP (Let's Encrypt ACME Challenge)
      443   # Caddy HTTPS
    ];

    # Alles andere blockieren — NetBird öffnet seine Ports selbst
  };
}
