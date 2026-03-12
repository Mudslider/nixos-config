{ ... }:

{
  # ── SSD-Buffer Verzeichnisse ──────────────────────────────
  # Alle eingehenden Daten landen zuerst auf der schnellen SSD.
  # Nachts werden sie auf den ZFS-Pool (HDD) verschoben/kopiert.

  systemd.tmpfiles.rules = [
    # Hauptverzeichnis
    "d /srv/ssd-buffer          0755 root  root -"

    # Backup: Restic-Repository vom Arbeitsrechner
    "d /srv/ssd-buffer/backup   0755 restic restic -"
    # Fotos: Eingang von Handys (Immich/Syncthing)
    "d /srv/ssd-buffer/photos   0750 philip philip -"

    # Dokumente: PaperlessNGX consume-Ordner
    "d /srv/ssd-buffer/documents 0750 philip philip -"

    # ── ZFS-Tank Unterverzeichnisse ─────────────────────
    # (Datasets werden als ZFS-Datasets erstellt,
    #  Unterordner innerhalb der Datasets per tmpfiles)
    "d /tank/media/filme         0755 philip philip -"
    "d /tank/media/serien        0755 philip philip -"
    "d /tank/media/musik         0755 philip philip -"
    "d /tank/media/audiobooks    0755 philip philip -"
    "d /tank/media/podcasts      0755 philip philip -"

    # Dienste-Daten (bleiben auf der SSD, werden nicht verschoben)
    "d /srv/ssd-buffer/services 0755 root  root -"
    "d /srv/ssd-buffer/services/nextcloud    0750 root root -"    
    "d /srv/ssd-buffer/services/paperless    0750 root      root      -"
    "d /srv/ssd-buffer/services/paperless/data   0750 root  root      -"
    "d /srv/ssd-buffer/services/paperless/media  0750 root  root      -"
    "d /srv/ssd-buffer/services/vaultwarden  0750 vaultwarden vaultwarden -"
    "d /srv/ssd-buffer/services/vaultwarden/backup 0750 vaultwarden vaultwarden -"    
    "d /srv/ssd-buffer/services/forgejo      0750 root root -"
    "d /srv/ssd-buffer/services/hass         0750 root root -"
    "d /srv/ssd-buffer/services/uptime-kuma  0750 root      root      -"
    "d /srv/ssd-buffer/services/grafana      0750 grafana   grafana   -"
    "d /srv/ssd-buffer/services/audiobookshelf        0750 root root  -"
    "d /srv/ssd-buffer/services/audiobookshelf/config  0750 root root -"
    "d /srv/ssd-buffer/services/audiobookshelf/metadata 0750 root root -"
    "d /srv/ssd-buffer/services/navidrome    0750 root      root      -"
    "d /srv/ssd-buffer/services/syncthing    0750 philip    philip    -"
    "d /srv/ssd-buffer/services/rustdesk     0750 root      root      -"
  ];
}
