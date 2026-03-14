{ ... }:

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
      environment = {
        POSTGRES_PASSWORD = "immich";  # Interne DB, nur im Container-Netz
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
        "/tank/photos/extern:/mnt/extern:ro"
      ];
      environment = {
        DB_HOSTNAME = "immich-postgres";
        DB_USERNAME = "immich";
        DB_PASSWORD = "immich";
        DB_DATABASE_NAME = "immich";
        REDIS_HOSTNAME = "immich-redis";
        IMMICH_MACHINE_LEARNING_URL = "http://immich-ml:3003";
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

  # Systemd-Abhängigkeit: Netzwerk muss vor Containern existieren
  systemd.services.podman-immich-redis.after = [ "podman-network-immich.service" ];
  systemd.services.podman-immich-postgres.after = [ "podman-network-immich.service" ];
  systemd.services.podman-immich-server.after = [ "podman-network-immich.service" ];
  systemd.services.podman-immich-ml.after = [ "podman-network-immich.service" ];
}
