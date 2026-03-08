{ config, ... }:

{
  # ── NetBird Mesh-VPN ──────────────────────────────────────
  # Gehostete Instanz: app.netbird.io (keine eigene managementURL nötig)

  services.netbird.clients.wt0 = {
    # Automatischer Login mit Setup-Key (ideal für Headless-Server)
    login = {
      enable = true;
      setupKeyFile = config.sops.secrets.netbird-setup-key.path;
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
