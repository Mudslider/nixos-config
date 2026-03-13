{ config, ... }:

{
  # ── NetBird (Mesh-VPN zum Homeserver) ─────────────────────
  # Verbindet den VPS mit dem Homeserver über WireGuard.
  # Setup-Key: Einmalig in app.netbird.io erstellen, dann:
  #   sudo bash -c 'echo "SETUP_KEY" > /run/secrets/netbird-setup-key'
  # Oder nach sops-Integration via secrets.yaml.

  services.netbird.clients.wt0 = {
    login = {
      enable = true;
      setupKeyFile = config.sops.secrets.netbird-setup-key.path;
    };
    port = 51820;
    ui.enable = false;
    openFirewall = true;
    openInternalFirewall = true;
  };

  sops.secrets.netbird-setup-key = {};

  services.resolved.enable = true;
}
