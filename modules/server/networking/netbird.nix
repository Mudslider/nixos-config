{ config, ... }:

{
  # ── NetBird Mesh-VPN ──────────────────────────────────────
  # Ersetzt WireGuard + Tailscale als einheitliche VPN-Lösung.
  # Der Koordinationsserver wird vom Freund gehostet.

  services.netbird.clients.wt0 = {
    # Automatischer Login mit Setup-Key (ideal für Headless-Server)
    login = {
      enable = true;
      setupKeyFile = config.sops.secrets.netbird-setup-key.path;

      # ── Management-URL des Freundes (einkommentieren + anpassen) ──
      # Falls die NetBird-Instanz deines Freundes eine eigene URL hat:
      # managementURL = "https://netbird.freund-domain.de";
    };

    # WireGuard-Port
    port = 51820;

    # Kein GUI auf Headless-Server
    ui.enable = false;

    # Firewall-Ports für direkte P2P-Verbindung öffnen
    openFirewall = true;

    # Interne Firewall-Regeln für NetBird-Netzwerk
    openInternalFirewall = true;
  };

  # systemd-resolved für NetBird-DNS-Auflösung
  services.resolved.enable = true;
}
