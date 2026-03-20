{ config, ... }:

{
  # ── Immich ────────────────────────────────────────────────
  # Foto- und Video-Management mit ML-basierter Erkennung
  # MUSS als Container laufen (Projekt-Empfehlung)

  virtualisation.oci-containers.containers = {
    immich-redis = {
      image = "docker.io/library/redis:7-alpine";
      extraOptions = [ "--network=immich-net" ];
      autoStart = true;
    };

    immich-postgres = {
      image = "docker.io/tensorchord/pgvecto-rs:pg16-v0.2.1";
      extraOptions = [ "--network=immich-net" ];
      volumes = [
        "immich-pgdata:/var/lib/postgresql/data"
      ];
      environmentFiles = [ config.sops.templates."immich-postgres-env".path ];
      environment = {
        POSTGRES_USER = "immich";
        POSTGRES_DB = "immich";
        POSTGRES_INITDB_ARGS = "--data-checksums";
      };
      autoStart = true;
    };

    immich-server = {
      image = "ghcr.io/immich-app/immich-server:v2.5.6";
      ports = [ "127.0.0.1:2283:2283" ];
      extraOptions = [ "--network=immich-net" ];
      dependsOn = [ "immich-redis" "immich-postgres" ];
      volumes = [
        "/tank/photos:/usr/src/app/upload"
        "/srv/ssd-buffer/immich-thumbs:/usr/src/app/upload/thumbs"
        "/tank/photos/extern:/mnt/extern:ro"
      ];
      environmentFiles = [ config.sops.templates."immich-server-env".path ];
      environment = {
        DB_HOSTNAME = "immich-postgres";
        DB_USERNAME = "immich";
        DB_DATABASE_NAME = "immich";
        REDIS_HOSTNAME = "immich-redis";
        # ML-URL wird über Immich Admin-UI gesteuert (flexibel umschaltbar)
        # Standard: http://immich-ml:3003 (lokaler Container)
        TZ = "Europe/Berlin";
      };
      autoStart = true;
    };

    immich-ml = {
      image = "ghcr.io/immich-app/immich-machine-learning:v2.5.6";
      extraOptions = [ "--network=immich-net" "--cpus=1.5" ];
      volumes = [
        "immich-ml-cache:/cache"
      ];
      environment = {
        TZ = "Europe/Berlin";
      };
      autoStart = true;
    };
  };

  # Systemd-Abhängigkeiten: Netzwerk + ZFS-Mount müssen vor Containern existieren
  # requires = harter Dependency — Container starten NICHT wenn ZFS nicht gemountet ist
  systemd.services.podman-immich-redis.after = [ "podman-network-immich.service" "zfs-mount.service" ];
  systemd.services.podman-immich-redis.requires = [ "zfs-mount.service" ];
  systemd.services.podman-immich-postgres.after = [ "podman-network-immich.service" "zfs-mount.service" ];
  systemd.services.podman-immich-postgres.requires = [ "zfs-mount.service" ];
  systemd.services.podman-immich-server.after = [ "podman-network-immich.service" "zfs-mount.service" ];
  systemd.services.podman-immich-server.requires = [ "zfs-mount.service" ];
  systemd.services.podman-immich-ml.after = [ "podman-network-immich.service" "zfs-mount.service" ];
  systemd.services.podman-immich-ml.requires = [ "zfs-mount.service" ];

  # ── SOPS-Templates für DB-Passwort ───────────────────────
  # Passwort wird aus secrets.yaml entschlüsselt und als Env-Datei bereitgestellt
  sops.templates."immich-postgres-env" = {
    content = ''
      POSTGRES_PASSWORD=${config.sops.placeholder."immich-db-password"}
    '';
  };
  sops.templates."immich-server-env" = {
    content = ''
      DB_PASSWORD=${config.sops.placeholder."immich-db-password"}
    '';
  };

  # Immich-Verzeichnisse auf ZFS anlegen (werden beim ersten Start benötigt)
  systemd.tmpfiles.rules = [
    "d /tank/photos/upload        0755 root root -"
    "d /tank/photos/library       0755 root root -"
    "d /tank/photos/profile       0755 root root -"
    "d /tank/photos/backups       0755 root root -"
    "d /tank/photos/encoded-video 0755 root root -"
    # Marker-Dateien: Immich prüft .immich in jedem Volume-Root
    # thumbs → /srv/ssd-buffer/immich-thumbs (SSD-Buffer, eigenes Volume!)
    "f /srv/ssd-buffer/immich-thumbs/.immich 0644 root root -"
    "f /tank/photos/upload/.immich        0644 root root -"
    "f /tank/photos/library/.immich       0644 root root -"
    "f /tank/photos/profile/.immich       0644 root root -"
    "f /tank/photos/backups/.immich       0644 root root -"
    "f /tank/photos/encoded-video/.immich 0644 root root -"
  ];
}
