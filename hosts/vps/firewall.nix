{ ... }:

{
  # ── Firewall (VPS — öffentlich erreichbar) ─────────────────
  networking.firewall = {
    enable = true;

    allowedTCPPorts = [
      2222  # SSH (nicht Standard-Port 22, reduziert Scan-Noise)
      80    # Caddy HTTP (Let's Encrypt ACME Challenge)
      443   # Caddy HTTPS
    ];

    # Alles andere blockieren — NetBird öffnet seine Ports selbst
  };
}
