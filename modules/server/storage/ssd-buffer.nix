{ ... }:

{
  # ── SSD-Buffer Verzeichnisse ──────────────────────────────
  # Alle eingehenden Daten landen zuerst auf der schnellen SSD.
  # Nachts werden sie auf den ZFS-Pool (HDD) verschoben/kopiert.

  systemd.tmpfiles.rules = [
    # Hauptverzeichnis
    "d /srv/ssd-buffer          0755 root  root -"

    # Backup: Restic REST-Server Repos (eines pro Client)
    "d /srv/ssd-buffer/backup        0770 restic restic -"
    "d /srv/ssd-buffer/backup/nora   0770 restic restic -"
    "d /srv/ssd-buffer/backup/polly  0770 restic restic -"
    # Fotos: Eingang von Handys (Immich/Syncthing)
    "d /srv/ssd-buffer/photos   0750 philip philip -"

    # Dokumente: PaperlessNGX consume-Ordner
    "d /srv/ssd-buffer/documents 0750 philip philip -"

    # Immich Thumbnails auf SSD (schnelles Browsen ohne HDD-Spinup)
    "d /srv/ssd-buffer/immich-thumbs 0755 root root -"

    # ── ZFS-Tank Unterverzeichnisse ─────────────────────
    # (Datasets werden als ZFS-Datasets erstellt,
    #  Unterordner innerhalb der Datasets per tmpfiles)
    # Immich External Library (externe Foto-Bibliothek, read-only eingebunden)
    "d /tank/photos/extern       0755 philip philip -"

    "d /tank/media/filme         0755 philip philip -"
    "d /tank/media/serien        0755 philip philip -"
    "d /tank/media/musik         0755 philip philip -"
    "d /tank/media/audiobooks    0755 philip philip -"
    "d /tank/media/podcasts      0755 philip philip -"

    # Dienste-Daten (bleiben auf der SSD, werden nicht verschoben)
    "d /srv/ssd-buffer/services 0755 root  root -"
    "d /srv/ssd-buffer/services/nextcloud    0750 root root -"    
    "d /srv/ssd-buffer/services/paperless    0750 1000 1000 -"
    "d /srv/ssd-buffer/services/paperless/data   0750 1000 1000 -"
    "d /srv/ssd-buffer/services/paperless/media  0750 1000 1000 -"
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
    "d /srv/ssd-buffer/services/backrest     0750 restic restic -"
    "d /srv/ssd-buffer/services/backrest/cache 0750 restic restic -"
  ];
}
