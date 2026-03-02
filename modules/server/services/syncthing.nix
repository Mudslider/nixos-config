{ ... }:

{
  # ── Syncthing ─────────────────────────────────────────────
  # Datei-Synchronisation für Laptops im Haushalt
  # (Handy-Fotos werden primär über Immich gesichert)

  services.syncthing = {
    enable = true;
    user = "philip";
    group = "philip";
    dataDir = "/srv/ssd-buffer/photos"; # Standard-Sync-Verzeichnis
    configDir = "/srv/ssd-buffer/services/syncthing";
    openDefaultPorts = true;

    settings = {
      gui = {
        address = "127.0.0.1:8384"; # Nur lokal, Zugriff über SSH-Tunnel
      };
      options = {
        urAccepted = -1;              # Telemetrie deaktivieren
        localAnnounceEnabled = true;  # Geräte im LAN finden
        globalAnnounceEnabled = true;
      };
    };

    # Ordner und Geräte werden über die Web-UI konfiguriert.
    # Zugriff: ssh -L 8384:localhost:8384 philip@192.168.1.10
    # Dann: http://localhost:8384
  };
}
