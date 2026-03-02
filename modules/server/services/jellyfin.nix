{ ... }:

{
  # ── Jellyfin ──────────────────────────────────────────────
  # Medienserver mit Intel Quick Sync Hardware-Transcoding

  services.jellyfin = {
    enable = true;
    openFirewall = false; # Zugriff nur über Caddy Reverse Proxy
  };

  # GPU-Zugriff für Hardware-Transcoding (Intel Quick Sync)
  users.users.jellyfin.extraGroups = [ "render" "video" ];

  # Medien-Verzeichnisse auf dem ZFS-Pool:
  # /tank/media/filme
  # /tank/media/serien
  # /tank/media/musik
  # Konfiguriere die Bibliotheken in der Jellyfin Web-UI
}
