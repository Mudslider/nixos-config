{ config, ... }:

{
  # ── PaperlessNGX ──────────────────────────────────────────
  # Dokumentenmanagement mit OCR (Tesseract + ML)
  # Als Container wegen komplexer Python/ML-Abhängigkeiten

  virtualisation.oci-containers.containers = {
    paperless-redis = {
      image = "docker.io/library/redis:7-alpine";
      extraOptions = [ "--network=paperless-net" ];
      autoStart = true;
    };

    paperless = {
      image = "ghcr.io/paperless-ngx/paperless-ngx:latest";
      # TODO: Pinne Version, z.B.: ghcr.io/paperless-ngx/paperless-ngx:2.14.7
      ports = [ "8000:8000" ];
      extraOptions = [ "--network=paperless-net" ];
      dependsOn = [ "paperless-redis" ];
      volumes = [
        "/srv/ssd-buffer/services/paperless/data:/usr/src/paperless/data"
        "/srv/ssd-buffer/services/paperless/media:/usr/src/paperless/media"
        "/srv/ssd-buffer/documents:/usr/src/paperless/consume"
      ];
      environment = {
        PAPERLESS_REDIS = "redis://paperless-redis:6379";
        PAPERLESS_OCR_LANGUAGE = "deu+eng";
        PAPERLESS_TIME_ZONE = "Europe/Berlin";
        PAPERLESS_URL = "https://paperless.home.lan";
        PAPERLESS_ADMIN_USER = "philip";
        PAPERLESS_ADMIN_PASSWORD = "changeme"; # TODO: Sofort nach Erstlogin ändern!
        PAPERLESS_OCR_MODE = "skip_noarchive";
        PAPERLESS_TASK_WORKERS = "2"; # N100: nicht mehr als 2
        PAPERLESS_FILENAME_FORMAT = "{created_year}/{correspondent}/{title}";
      };
      autoStart = true;
    };
  };

  # Systemd-Abhängigkeit: Netzwerk muss vor Containern existieren
  systemd.services.podman-paperless-redis.after = [ "podman-network-paperless.service" ];
  systemd.services.podman-paperless.after = [ "podman-network-paperless.service" ];
}
